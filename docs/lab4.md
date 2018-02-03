# Lab 4

主要改动有

* 进程管理
  * `kern/process/proc.c`
  * `kern/process/proc.h`
* 进程切换
  * `kern/process/switch.S`
  * `kern/process/entry.S`
  * `kern/trap/trapentry.S`

## RISC-V Calling Convention

| Register | ABI Name | Description                      | Saver  |
| -------- | -------- | -------------------------------- | ------ |
| x0       | zero     | Hard-wired zero                  | ------ |
| x1       | ra       | Return address                   | Caller |
| x2       | sp       | Stack pointer                    | Callee |
| x3       | gp       | Global pointer                   | ------ |
| x4       | tp       | Thread pointer                   | ------ |
| x5-7     | t0-2     | Temporaries                      | Caller |
| x8       | s0/fp    | Saved register/frame pointer     | Callee |
| x9       | s1       | Saved register                   | Callee |
| x10-11   | a0-1     | Function arguments/return values | Caller |
| x12-17   | a2-7     | Function arguments               | Caller |
| x18-27   | s2-11    | Saved registers                  | Callee |
| x28-31   | t3-6     | Temporaries                      | Caller |

我们切换进程时需要保存Callee-saved registers以及`ra`。

## Data Structures

根据需求，将进程上下文对应的数据结构修改如下

```c
struct context {
  uintptr_t ra;
  uintptr_t sp;
  uintptr_t s0;
  uintptr_t s1;
  uintptr_t s2;
  uintptr_t s3;
  uintptr_t s4;
  uintptr_t s5;
  uintptr_t s6;
  uintptr_t s7;
  uintptr_t s8;
  uintptr_t s9;
  uintptr_t s10;
  uintptr_t s11;
};
```

内核进程管理中设计到的关键函数有`kernel_thread`、`copy_thread`和`switch_to`，下面分别介绍。

## Kernel Thread

`kernel_thread`函数用于fork一个内核进程

```c
/**
 * @brief      create a kernel thread using "fn" function
 *
 * @param[in]  fn           The function
 * @param      arg          The argument
 * @param[in]  clone_flags  The clone flags
 *
 * @return     error code
 *
 * the contents of temp trapframe tf will be copied to proc->tf in
 * do_fork-->copy_thread function
 */
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
  struct trapframe tf;
  memset(&tf, 0, sizeof(struct trapframe));
  tf.gpr.s0 = (uintptr_t)fn;
  tf.gpr.s1 = (uintptr_t)arg;
  tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
  tf.epc = (uintptr_t)kernel_thread_entry;
  return do_fork(clone_flags | CLONE_VM, 0, &tf);
}
```

我们先将`fn`和`arg`临时存放在中断帧中以备之后使用，然后设置中断帧中的`sstatus`，使得返回后处于S-mode且中断使能的状态，最后设置`epc`，使中断返回后先执行`kernel_thread_entry函数`。

`do_fork`函数无改动，下面我们来看一下`do_fork`中用到的`copy_thread`函数。

## Copying a Thread

```c
/**
 * @brief      setup the trapframe on the process's kernel stack and
 *             setup the kernel entry point and stack of process
 *
 * @param      proc  The proc
 * @param[in]  esp   The user stack pointer of the parent
 * @param      tf    trapframe to copy to proc->tf
 */
static void copy_thread(struct proc_struct *proc, uintptr_t esp,
                        struct trapframe *tf) {
  proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
  *(proc->tf) = *tf;

  // Set a0 to 0 so a child process knows it's just forked
  proc->tf->gpr.a0 = 0;
  proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;

  proc->context.ra = (uintptr_t)forkret;
  proc->context.sp = (uintptr_t)(proc->tf);
}
```

我们首先在子进程的内核栈底端复制一份之前在`kernel_thread`中构造好的中断帧，然后将`a0`置为0以表示该进程为fork出的子进程。

由于我们fork的是内核进程，传入的`esp`为0，因此中断帧中的`sp`可以直接指向内核栈中的中断帧。

然后我们将进程上下文中的`ra`设为`forkret`，`sp`设为`proc->tf`，在完成`switch_to`后，会首先执行`forkret`函数，此时`sp`也已经切换到了相应的内核栈上。

这里将`a0`置0已及对`esp`的判断是为lab 5中fork用户进程做准备。

## Task Switch

`switch_to`的实现非常简单

```nasm
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
    STORE sp, 1*REGBYTES(a0)
    STORE s0, 2*REGBYTES(a0)
    STORE s1, 3*REGBYTES(a0)
    STORE s2, 4*REGBYTES(a0)
    STORE s3, 5*REGBYTES(a0)
    STORE s4, 6*REGBYTES(a0)
    STORE s5, 7*REGBYTES(a0)
    STORE s6, 8*REGBYTES(a0)
    STORE s7, 9*REGBYTES(a0)
    STORE s8, 10*REGBYTES(a0)
    STORE s9, 11*REGBYTES(a0)
    STORE s10, 12*REGBYTES(a0)
    STORE s11, 13*REGBYTES(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
    LOAD sp, 1*REGBYTES(a1)
    LOAD s0, 2*REGBYTES(a1)
    LOAD s1, 3*REGBYTES(a1)
    LOAD s2, 4*REGBYTES(a1)
    LOAD s3, 5*REGBYTES(a1)
    LOAD s4, 6*REGBYTES(a1)
    LOAD s5, 7*REGBYTES(a1)
    LOAD s6, 8*REGBYTES(a1)
    LOAD s7, 9*REGBYTES(a1)
    LOAD s8, 10*REGBYTES(a1)
    LOAD s9, 11*REGBYTES(a1)
    LOAD s10, 12*REGBYTES(a1)
    LOAD s11, 13*REGBYTES(a1)

    ret
```

对于刚fork出的进程，会首先进入`forkret`函数

```c
/**
 * @brief      the first kernel entry point of a new thread/process
 *
 * the addr of forkret is setted in copy_thread function after switch_to, the
 * current proc will execute here.
 */
static void forkret(void) {
  forkrets(current->tf);
}
```

`forkrets`为`kern/trap/trapentry.S`中的函数

```nasm
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
    j __trapret
```

执行完`__trapret`后，进程会到达我们之前在`tf->epc`中设置的

```nasm
.text
# void kernel_thread(void)
.globl kernel_thread_entry
kernel_thread_entry:        
    move a0, s1
    jalr s0

    jal do_exit
```

这里`s0`和`s1`就是我们之前设置好的`fn`和`arg`，至此，内核进程切换完成。