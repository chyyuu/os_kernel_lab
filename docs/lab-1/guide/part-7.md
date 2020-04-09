## 重写程序入口点 `_start`

我们在第一章中，曾自己重写了一个 C runtime 的入口点 `_start` ，在那里我们仅仅只是让它死循环。但是现在，类似 C runtime ，我们希望这个函数可以为我们设置内核的运行环境(不妨称为 kernel runtime ) 。随后，我们才真正开始执行内核的代码。

但是具体而言我们需要设置怎样的运行环境呢？

> **[info] 第一条指令**
>
> 在 CPU 加电或 reset 后，它首先会进行 **自检 (POST, Power-On Self-Test)** ，通过自检后会跳转到 **启动代码(bootloader)** 的入口。在 bootloader 中，我们进行外设探测，并对内核的运行环境进行初步设置。随后， bootloader 会将内核代码从硬盘 load 到内存中，并跳转到内核入口，正式进入内核。
>
> 所以 CPU 所执行的第一条指令是指 bootloader 的第一条指令。

幸运的是， 我们已经有现成的 bootloader 实现 -- [OpenSBI](https://github.com/riscv/opensbi) 固件(firmware)。

> **[info] firmware 固件**
>
> 在计算中，固件是一种特定的计算机软件，它为设备的特定硬件提供低级控制进一步加载其他软件的功能。固件可以为设备更复杂的软件（如操作系统）提供标准化的操作环境，或者，对于不太复杂的设备，充当设备的完整操作系统，执行所有控制、监视和数据操作功能。 在基于 x86 的计算机系统中, BIOS 或 UEFI 是一种固件；在基于 riscv 的计算机系统中，OpenSBI 是一种固件。

OpenSBI 固件运行在特权级别很高的计算机硬件环境中，即 riscv64 cpu 的 M Mode (CPU 加电后也就运行在 M Mode) ，我们将要实现的 OS 内核运行在 S Mode ， 而我们要支持的用户程序运行在 U Mode 。在开发过程中我们重点关注 S Mode 。

> **[info] riscv64 的特权级**
>
> 如图所示，共有如下几个特权级：
>
> ![](figures/privilege_levels.png)
>
> 从 U 到 S 再到 M，权限不断提高，这意味着你可以使用更多的特权指令，访需求权限更高的寄存器等等。我们可以使用一些指令来修改 CPU 的**当前特权级**。而当当前特权级不足以执行特权指令或访问一些寄存器时，CPU 会通过某种方式告诉我们。

OpenSBI 所做的一件事情就是把 CPU 从 M Mode 切换到 S Mode ，接着跳转到一个固定地址 0x80200000，开始执行内核代码。

> **[info] riscv64 的 M Mode**
>
> M-mode(机器模式，缩写为 M 模式)是 RISC-V 中 hart(hardware thread,硬件线程)可以执行的最高权限模式。在 M 模式下运行的 hart 对内存,I/O 和一些对于启动和配置系统来说必要的底层功能有着完全的使用权。
>
> **riscv64 的 S Mode**
>
> S-mode(监管者模式，缩写为 S 模式)是支持现代类 Unix 操作系统的权限模式，支持现代类 Unix 操作系统所需要的基于页面的虚拟内存机制是其核心。
>


接着我们要在 `_start` 中设置内核的运行环境了，我们直接来看代码：

```riscv
# src/boot/entry64.asm

    .section .text.entry
    .globl _start
_start:
    la sp, bootstacktop
    call rust_main

    .section .bss.stack
    .align 12
    .global bootstack
bootstack:
    .space 4096 * 4
    .global bootstacktop
bootstacktop:
```

可以看到之前未被定义的 *.bss.stack* 段出现了，我们只是在这里分配了一块 $$4096\times{4}\text{Bytes}=\text{16KiB}$$ 的内存作为内核的栈。之前的 *.text.entry* 也出现了：我们将 `_start` 函数放在了 *.text* 段的开头。

我们看看 `_start` 里面做了什么：

1. 修改栈指针寄存器 `sp` 为 *.bss.stack* 段的结束地址，由于栈是从高地址往低地址增长，所以高地址是栈顶；
2. 使用 `call` 指令跳转到 `rust_main` 。这意味着我们的内核运行环境设置完成了，正式进入内核。

我们将 `src/main.rs` 里面的 `_start` 函数删除，并换成 `rust_main` ：

```rust
// src/main.rs

#![feature(global_asm)]

global_asm!(include_str!("boot/entry64.asm"));

#[no_mangle]
pub extern "C" fn rust_main() -> ! {
    loop {}
}
```

到现在为止我们终于将一切都准备好了，接下来就要配合 OpenSBI 运行我们的内核！