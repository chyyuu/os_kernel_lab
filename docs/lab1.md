# Lab 1

lab 1的移植中，主要改动有以下几点

* I/O函数
  - `kern/driver/console.c`
* 中断处理例程
  - `kern/trap/`
* 时钟中断设置
  - `kern/driver/clock.c`

其中对中断处理例程和时钟中断做了较大改动

## I/O Functions

I/O部分的修改十分直观

```c
/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
  sbi_console_putchar((unsigned char)c);
}
```

## Interrupt Service Routine

### Setting Trap Entry

RISC-V中并无中断向量的概念，当发生中断时，硬件只负责将`pc`寄存器指向Interrupt Service Routine (ISR) 的入口处。ISR入口地址应当存放于`stvec`寄存器中，我们可以修改`idt_init`函数，在其中设置`stvec`寄存器

```c
/**
 * idt_init - initialize stvec to the entry points in kern/trap/trapentry.S
 */
void idt_init(void) {
  extern void __alltraps(void);
  // Set sscratch register to 0, indicating to exception vector that we are
  // presently executing in the kernel
  write_csr(sscratch, 0);
  // Set the exception vector address
  write_csr(stvec, &__alltraps);
  // enable interrupt
  set_csr(sstatus, SSTATUS_SIE);
}
```

将`sscratch`寄存器置0也许让人费解，我们会在lab 6中详细分析，这里是否置0其实并无影响。

### Data Structures

我们将中断帧对应的数据结构修改如下

```c
struct pushregs {
  uintptr_t zero;  // Hard-wired zero
  uintptr_t ra;    // Return address
  uintptr_t sp;    // Stack pointer
  uintptr_t gp;    // Global pointer
  uintptr_t tp;    // Thread pointer
  uintptr_t t0;    // Temporary
  uintptr_t t1;    // Temporary
  uintptr_t t2;    // Temporary
  uintptr_t s0;    // Saved register/frame pointer
  uintptr_t s1;    // Saved register
  uintptr_t a0;    // Function argument/return value
  uintptr_t a1;    // Function argument/return value
  uintptr_t a2;    // Function argument
  uintptr_t a3;    // Function argument
  uintptr_t a4;    // Function argument
  uintptr_t a5;    // Function argument
  uintptr_t a6;    // Function argument
  uintptr_t a7;    // Function argument
  uintptr_t s2;    // Saved register
  uintptr_t s3;    // Saved register
  uintptr_t s4;    // Saved register
  uintptr_t s5;    // Saved register
  uintptr_t s6;    // Saved register
  uintptr_t s7;    // Saved register
  uintptr_t s8;    // Saved register
  uintptr_t s9;    // Saved register
  uintptr_t s10;   // Saved register
  uintptr_t s11;   // Saved register
  uintptr_t t3;    // Temporary
  uintptr_t t4;    // Temporary
  uintptr_t t5;    // Temporary
  uintptr_t t6;    // Temporary
};
```

```c
struct trapframe {
  struct pushregs gpr;
  uintptr_t status;
  uintptr_t epc;
  uintptr_t badvaddr;
  uintptr_t cause;
};
```

### Trap Handling

我们定义了一些宏来帮助操作

```c
#if __riscv_xlen == 64
#define SLL32    sllw
#define STORE    sd
#define LOAD     ld
#define LWU      lwu
#define LOG_REGBYTES 3
#else
#define SLL32    sll
#define STORE    sw
#define LOAD     lw
#define LWU      lw
#define LOG_REGBYTES 2
#endif
#define REGBYTES (1 << LOG_REGBYTES)
```

ISR的主体并不复杂

```nasm
    .globl __alltraps
__alltraps:
    SAVE_ALL
    move  a0, sp
    jal trap
    .globl __trapret
__trapret:
    RESTORE_ALL
    # return from supervisor call
    sret
```

其中`SAVE_ALL`和`RESTORE_ALL`都是宏，分别定义如下

```nasm
    .macro SAVE_ALL
    # store sp in sscratch
    csrw sscratch, sp
    # provide room for trap frame
    addi sp, sp, -36 * REGBYTES
    # save x registers except x2 (sp)
    STORE  x1,1*REGBYTES(sp)
    STORE  x3,3*REGBYTES(sp)
    STORE  x4,4*REGBYTES(sp)
    STORE  x5,5*REGBYTES(sp)
    STORE  x6,6*REGBYTES(sp)
    STORE  x7,7*REGBYTES(sp)
    STORE  x8,8*REGBYTES(sp)
    STORE  x9,9*REGBYTES(sp)
    STORE  x10,10*REGBYTES(sp)
    STORE  x11,11*REGBYTES(sp)
    STORE  x12,12*REGBYTES(sp)
    STORE  x13,13*REGBYTES(sp)
    STORE  x14,14*REGBYTES(sp)
    STORE  x15,15*REGBYTES(sp)
    STORE  x16,16*REGBYTES(sp)
    STORE  x17,17*REGBYTES(sp)
    STORE  x18,18*REGBYTES(sp)
    STORE  x19,19*REGBYTES(sp)
    STORE  x20,20*REGBYTES(sp)
    STORE  x21,21*REGBYTES(sp)
    STORE  x22,22*REGBYTES(sp)
    STORE  x23,23*REGBYTES(sp)
    STORE  x24,24*REGBYTES(sp)
    STORE  x25,25*REGBYTES(sp)
    STORE  x26,26*REGBYTES(sp)
    STORE  x27,27*REGBYTES(sp)
    STORE  x28,28*REGBYTES(sp)
    STORE  x29,29*REGBYTES(sp)
    STORE  x30,30*REGBYTES(sp)
    STORE  x31,31*REGBYTES(sp)

    # get sp, sstatus, sepc, sbadvaddr, scause
    csrr s0, sscratch
    csrr s1, sstatus
    csrr s2, sepc
    csrr s3, sbadaddr
    csrr s4, scause
    # store sp, sstatus, sepc, sbadvaddr, scause
    STORE s0, 2*REGBYTES(sp)
    STORE s1, 32*REGBYTES(sp)
    STORE s2, 33*REGBYTES(sp)
    STORE s3, 34*REGBYTES(sp)
    STORE s4, 35*REGBYTES(sp)
    .endm
```

```nasm
    .macro RESTORE_ALL
    # sstatus and sepc may be changed in ISR
    LOAD s1, 32*REGBYTES(sp)
    LOAD s2, 33*REGBYTES(sp)
    csrw sstatus, s1
    csrw sepc, s2

    # restore x registers except x2 (sp)
    LOAD  x1,1*REGBYTES(sp)
    LOAD  x3,3*REGBYTES(sp)
    LOAD  x4,4*REGBYTES(sp)
    LOAD  x5,5*REGBYTES(sp)
    LOAD  x6,6*REGBYTES(sp)
    LOAD  x7,7*REGBYTES(sp)
    LOAD  x8,8*REGBYTES(sp)
    LOAD  x9,9*REGBYTES(sp)
    LOAD  x10,10*REGBYTES(sp)
    LOAD  x11,11*REGBYTES(sp)
    LOAD  x12,12*REGBYTES(sp)
    LOAD  x13,13*REGBYTES(sp)
    LOAD  x14,14*REGBYTES(sp)
    LOAD  x15,15*REGBYTES(sp)
    LOAD  x16,16*REGBYTES(sp)
    LOAD  x17,17*REGBYTES(sp)
    LOAD  x18,18*REGBYTES(sp)
    LOAD  x19,19*REGBYTES(sp)
    LOAD  x20,20*REGBYTES(sp)
    LOAD  x21,21*REGBYTES(sp)
    LOAD  x22,22*REGBYTES(sp)
    LOAD  x23,23*REGBYTES(sp)
    LOAD  x24,24*REGBYTES(sp)
    LOAD  x25,25*REGBYTES(sp)
    LOAD  x26,26*REGBYTES(sp)
    LOAD  x27,27*REGBYTES(sp)
    LOAD  x28,28*REGBYTES(sp)
    LOAD  x29,29*REGBYTES(sp)
    LOAD  x30,30*REGBYTES(sp)
    LOAD  x31,31*REGBYTES(sp)
    # restore sp last
    LOAD  x2,2*REGBYTES(sp)
    .endm
```

这两部分应该较容易理解，现在我们来看看`trap`函数的实现

```c
/**
 * trap - handles an exception/interrupt. If and when trap() returns, the code
 * in kern/trap/trapentry.S restores the old CPU state saved in the trapframe
 * and then uses the sret instruction to return from the exception.
 */
void trap(struct trapframe *tf) {
  // dispatch based on what type of trap occurred
  if ((intptr_t)tf->cause < 0) {
    // interrupts
    interrupt_handler(tf);
  } else {
    // exceptions
    exception_handler(tf);
  }
}
```

RISC-V ISA规定当`scause`的Most Significant Bit (MSB) 为0时表示exception，为1时表示interrupt，因此我们可以通过`(intptr_t)tf->cause`的符号快速判断trap的类型，接下来只需在`interrupt_handler`和`exception_handler`中做相应处理即可。

## Timer Interrupt

### Getting Time

我们首先要面对的问题是读取时间，我们在[Instruction Emulation](toolchain-overview.md)中已经提到过`rdtime`指令的细节，这里我们只关注kernel层面对时间的读取

```c
static inline uint64_t get_cycles(void) {
#if __riscv_xlen == 64
  uint64_t n;
  __asm__ __volatile__("rdtime %0" : "=r"(n));
  return n;
#else
  uint32_t lo, hi, tmp;
  __asm__ __volatile__(
      "1:\n"
      "rdtimeh %0\n"
      "rdtime %1\n"
      "rdtimeh %2\n"
      "bne %0, %2, 1b"
      : "=&r"(hi), "=&r"(lo), "=&r"(tmp));
  return ((uint64_t)hi << 32) | lo;
#endif
}
```

由于`mtime`为64位寄存器，在32位环境下的读取过程并不直观

1. 读取`mtime`的高32位到`hi`中
2. 读取`mtime`的低32位到`lo`中
3. 读取`mtime`的高32位到`tmp`中
4. 若`hi != tmp`，返回第1步
5. 将`hi`和`lo`拼接后返回

汇编中`1b`表示前一个label 1处，类似的，`1f`表示后一个label 1处。

### Clock Initialization

```c
static uint64_t timebase;
/* *
 * clock_init - initialize clock to interrupt 100 times per second
 * */
void clock_init(void) {
  // divided by 500 when using Spike (2MHz)
  // divided by 100 when using QEMU (10MHz)
  timebase = sbi_timebase() / 100;
  // initialize time counter 'ticks' to zero
  ticks = 0;

  clock_set_next_event();
  cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) {
  sbi_set_timer(get_cycles() + timebase);
}
```

`sbi_timebase`会返回CPU工作频率，由于我们需要100Hz的时钟，将返回值除以100即可得到两次时钟中断间隔的周期数。Spike模拟器虽然运行频率只有2MHz，但返回值也为10MHz，所以若使用Spike模拟器，建议除以500。

### Handling Timer Interrupt

> All bits besides SSIP and USIP in the sip register are read-only.
>
> — Privileged ISA Specification v1.9.1, 4.1.4

时钟中断的处理非常简单

```c
void interrupt_handler(struct trapframe *tf) {
  // remove MSB
  intptr_t cause = (tf->cause << 1) >> 1;
  switch (cause) {
    case IRQ_S_TIMER:
      clock_set_next_event();
      if (++ticks % TICK_NUM == 0) {
        print_ticks();
      }
      break;
    default:
      print_trapframe(tf);
      break;
  }
}
```

然而bbl中的底层实现却并不trivial，我们先来看看`sbi_set_timer`在bbl中调用的`mcall_set_timer`

```c
static uintptr_t mcall_set_timer(uint64_t when)
{
  *HLS()->timecmp = when;
  clear_csr(mip, MIP_STIP);
  set_csr(mie, MIP_MTIP);
  return 0;
}
```

该函数先将`mtimecmp`寄存器设置为用户给定的时间，然后清空`mip`中的Supervisor Timer Interrupt Pending Bit (STIP)，设置`mie`中的Machine Timer Interrupt Enable Bit (MTIE，与MTIP位置相同) 以使能M-mode下的时钟中断。发生时钟中断时，会由bbl中的ISR处理，并一步步转发到`timer_interrupt`函数中

```c
uintptr_t timer_interrupt()
{
  // just send the timer interrupt to the supervisor
  clear_csr(mie, MIP_MTIP);
  set_csr(mip, MIP_STIP);

  // and poll the HTIF console
  htif_interrupt();

  return 0;
}
```

首先清空`mie`中的Machine Timer Interrupt Enable Bit，然后设置`mip`中的Supervisor Timer Interrupt Pending Bit (STIP)，返回S-mode后，由于`sip`寄存器中STIP被置为1，立即引发一个时钟中断。在ISR中，我们调用的`clock_set_next_event`会调用`sbi_set_timer`并被bbl中的`mcall_set_timer`处理，从而清空`sip`中的STIP位，又回到了开始的状态。

以上对时钟中断的处理流程和Spike模拟器的undocumented feature耦合十分紧密，处理SEE和模拟器层的读者应特别注意。