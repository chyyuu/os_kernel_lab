# Lab 5

改动部分有

* 进程管理
  * `kern/process/proc.c`
* 系统调用
  * `kern/syscall/syscall.c`
  * `kern/process/proc.c`

## Workaround for Compiler Bug

> The difficulty of a bug can be measured as the distance, in lines of code, from the cause of a bug to the visible symptom of a bug.
>
> —Rusty Klophaus

之前已经提到，传入`-b binary`选项会导致`ld`出现`segmentation fault`，但我们要将用户态程序嵌入kernel的二进制文件中，因而不得不使用`ld`的这项功能。经过对`ld`中二进制文件操作相关编译选项的暴力枚举，我们发现将Makefile中的

```
$(V)$(LD) $(LDFLAGS) -T tools/kernel.ld -o $@ $(KOBJS) -b binary $(USER_BINS)
```

改为

```makefile
$(V)$(LD) $(LDFLAGS) -T tools/kernel.ld -o $@ $(KOBJS) --format=binary $(USER_BINS) --format=default
```

即可解决问题。

有兴趣的读者可以尝试解决这个bug，下面是一些参考资料

* [Segment fault when relax enable](https://github.com/riscv/riscv-gnu-toolchain/issues/193)
* [Error during linking after clang compile](https://groups.google.com/a/groups.riscv.org/forum/#!topic/sw-dev/0tlptEkGyJA)
* [Using LD, the GNU linker - Options](ftp://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_node/ld_3.html)
* [Include binary file with GNU ld linker script](http://stackoverflow.com/questions/327609/include-binary-file-with-gnu-ld-linker-script)

## Syscall

首先，我们需要在ISR中增加对系统调用的处理程序

```c
void exception_handler(struct trapframe *tf) {
  switch (tf->cause) {
    case CAUSE_USER_ECALL:
      tf->epc += 4;
    case CAUSE_SUPERVISOR_ECALL:
      syscall();
      break;
    default:
      print_trapframe(tf);
      break;
  }
}
```

此处调用的`syscall`实现如下

```c
void syscall(void) {
  struct trapframe *tf = current->tf;
  uint32_t arg[5];
  int num = tf->gpr.a0;
  if (num >= 0 && num < NUM_SYSCALLS) {
    if (syscalls[num] != NULL) {
      arg[0] = tf->gpr.a1;
      arg[1] = tf->gpr.a2;
      arg[2] = tf->gpr.a3;
      arg[3] = tf->gpr.a4;
      arg[4] = tf->gpr.a5;
      tf->gpr.a0 = syscalls[num](arg);
      return;
    }
  }
  print_trapframe(tf);
  panic("undefined syscall %d, pid = %d, name = %s.\n", num, current->pid,
        current->name);
}
```

我们规定`a0`用于存放系统调用号`a1-5`用于存放系统调用参数，最后返回值放入`a0`寄存器。

## Loading User Program

首先让我们来看看`kernel_execve`函数

```c

/**
 * @brief      exec a user program by doing SYS_exec syscall
 *
 * @param[in]  name    The name of user program
 * @param      binary  The binary file of user program
 * @param[in]  size    The size of user program
 *
 * @return     error code
 */
static int kernel_execve(const char *name, unsigned char *binary, size_t size) {
  int ret, len = strlen(name);

  asm volatile(
      "li a0, %1\n"
      "lw a1, %2\n"
      "lw a2, %3\n"
      "lw a3, %4\n"
      "lw a4, %5\n"
      "li a7, 10\n"
      "ecall\n"
      "sw a0, %0"
      : "=m"(ret)
      : "i"(SYS_exec), "m"(name), "m"(len), "m"(binary), "m"(size)
      : "memory");

  return ret;
}
```

其中的汇编部分与`syscall`函数对应。再考察`load_icode`函数，其中改动的部分只有涉及中断帧的几行代码

```c
struct trapframe *tf = current->tf;
// keep sstatus
uintptr_t sstatus = tf->status;
memset(tf, 0, sizeof(struct trapframe));
/**
 * LAB5:EXERCISE1 YOUR CODE
 * You should set sp, epc accordingly
 * If we set trapframe correctly, then the user level process can return to USER
 * MODE from kernel.
 *      (1) sp should be the top addr of user stack (USTACKTOP)
 *      (2) epc should be the entry point of this binary program (elf->e_entry)
 */
tf->gpr.sp = USTACKTOP;
tf->epc = elf->e_entry;
tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
```

注意对`sstatus`的修改，这样中断返回后就会进入用户态。

## Redirecting Syscall in BBL

bbl-ucore中第一个用户进程的启动方法如下

* 通过系统调用获得一个中断帧
* 修改中断帧
* 从中断中返回

可以看出，我们需要在supervisor中主动引发一个中断以获得一个中断帧，然而，在S-mode使用`ecall`指令会直接进入bbl的ISR中，为此我们对bbl做了小幅修改，将这个`SYS_exec`中断直接转发给kernel

```c
void mcall_trap(uintptr_t* regs, uintptr_t mcause, uintptr_t mepc)
{
  uintptr_t n = regs[17], arg0 = regs[10], arg1 = regs[11], retval;
  switch (n)
  {
    case MCALL_HART_ID:
      retval = mcall_hart_id();
      break;
    case MCALL_CONSOLE_PUTCHAR:
      retval = mcall_console_putchar(arg0);
      break;
    case MCALL_CONSOLE_GETCHAR:
      retval = mcall_console_getchar();
      break;
    case MCALL_SET_TIMER:
      retval = mcall_set_timer(arg0);
      break;
    default:
      // Workaround for creating first user process in Lab 5
      redirect_trap(mepc, read_csr(mstatus));
      retval = 0;
      break;
  }
  regs[10] = retval;
  write_csr(mepc, mepc + 4);
}
```

## Multitasking in RISC-V

我们知道，在x86架构下，每个用户态进程都拥有一个内核栈和一个用户栈，我们的操作系统利用x86的TSS的机制来完成权限转换时对栈的切换，而RISC-V下并没有TSS，我们需要借助`sscratch`寄存器完成类似的功能。

### Switching Stack in M-mode

首先我们先来看看从S-mode或U-mode到M-mode时如何完成栈的切换，这里涉及到`mscratch`寄存器和[`csrrw`](#riscv-overview.md)特权指令。

当CPU加电时，我们要先清空`mscratch`寄存器

```nasm
csrw mscratch, x0
```

任何情况下，在离开M-mode之前，要将`sp`的值存入`mscratch`

```nasm
csrw mscratch, sp
```

只要保证以上行为，我们就可以保证以下两点为真

1. 只要处于M-mode，`mscratch`寄存器的值就为0
2. 只要不在M-mode，`mscratch`寄存器就保存了"machine stack"的值

现在，想象某个状态下发生中断并到达了M-mode的ISR入口，我们对这个中断的来源一无所知。现在，执行以下命令

```nasm
# swap sp and mscratch
csrrw sp, mscratch, sp
```

现在，`sp`和`mscratch`的值可根据中断的来源分为三种情况

1. 中断来自M-mode
   * `sp == 0`
   * `mscratch == "machine stack"`
2. 中断来自S-mode
   * `sp == "machine stack"`
   * `mscratch == "kernel stack"`
3. 中断来自U-mode
   * `sp == "machine stack"`
   * `mscratch == "user stack"`

如果读者感到理解困难，可以尝试在草稿纸上分析三种情况下中断前后`mscratch`和`sp`的状态。

容易看到，通过检查`sp`的值足以判断中断是否来自M-mode，我们可以根据这一信息决定是否对栈进行切换操作

```nasm
# swap sp and mscratch
csrrw sp, mscratch, sp
beqz sp, .Ltrap_from_machine_mode
```

同样，在S-mode下也有一个功能类似的`sscratch`寄存器，由于S-mode下要处理的情况较多，具体的实现要更加复杂

### Switching Stack in S-mode

内核态ISR入口如下

```nasm
	csrrw sp, sscratch, sp
    bnez sp, _save_context
_restore_kernel_sp:
    csrr sp, sscratch
_save_context:
    addi sp, sp, -36 * REGBYTES
    # save registers
    sw x1, 1 * REGBYTES(sp)
    sw x3, 3 * REGBYTES(sp)
    ......
    sw x31, 31 * REGBYTES(sp)
    # Set sscratch to 0, so that if a recursive
    # exception occurs, we know it came from the kernel
    csrrw s0, sscratch, x0
    sw s0, 2 * REGBYTES(sp)
```

在完成对中断的处理后，在ISR出口的处理如下

```nasm
	lw s1, 32 * REGBYTES(sp) # s1 = tf->sstatus
    andi s0, s1, SSTATUS_SPP # back to U-mode?
    bnez s0, _restore_context
_save_kernel_sp:
    addi s0, sp, 36 * REGBYTES # Save kernel stack
    csrw sscratch, s0
_restore_context:
    # restore registers
    lw x1, 1 * REGBYTES(sp)
    lw x3, 3 * REGBYTES(sp)
    ......
    lw x31, 31 * REGBYTES(sp)
    # restore sp last
    LOAD x2, 2*REGBYTES(sp)
```

读者可以分别假设中断来自U-mode和S-mode，观察两种情况下`sp`和`sscratch`的变化情况。
