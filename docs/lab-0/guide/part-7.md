## 重写程序入口点 `_start`

我们在第一章中，曾自己重写了一个入口点 `_start`，在那里我们仅仅只是让它死循环。但是现在，类似 C 语言运行时环境，我们希望这个函数可以为我们设置内核的运行环境。随后，我们才真正开始执行内核的代码。

但是具体而言我们需要设置怎样的运行环境呢？

> **[info] 第一条指令**
>
> 在 CPU 加电或 Reset 后，它首先会进行自检（POST, Power-On Self-Test），通过自检后会跳转到**启动代码（Bootloader）**的入口。在 bootloader 中，我们进行外设探测，并对内核的运行环境进行初步设置。随后，bootloader 会将内核代码从硬盘加载到内存中，并跳转到内核入口，正式进入内核。也就是说，CPU 所执行的第一条指令其实是指 bootloader 的第一条指令。

幸运的是， 我们已经有现成的 bootloader 实现 [OpenSBI](https://github.com/riscv/opensbi) 固件（Firmware）。

> **[info] Firmware 固件**
>
> 在计算中，固件是一种特定的计算机软件，它为设备的特定硬件提供低级控制进一步加载其他软件的功能。固件可以为设备更复杂的软件（如操作系统）提供标准化的操作环境，或者，对于不太复杂的设备，充当设备的完整操作系统，执行所有控制、监视和数据操作功能。在基于 x86 的计算机系统中, BIOS 或 UEFI 是一种固件；在基于 RISC-V 的计算机系统中，OpenSBI 是一种固件。

OpenSBI 固件运行在特权级别很高的计算机硬件环境中，即 RISC-V 64 的 M Mode（CPU 加电后也就运行在 M Mode），我们将要实现的 OS 内核运行在 S Mode，而我们要支持的用户程序运行在 U Mode。在开发过程中我们重点关注 S Mode。

> **[info] RISC-V 64 的特权级**
>
> RISC-V 共有 3 种特权级，分别是 U Mode（User / Application 模式）、S Mode（Supervisor 模式）和 M Mode（Machine 模式）。
> 
> 从 U 到 S 再到 M，权限不断提高，这意味着你可以使用更多的特权指令，访需求权限更高的寄存器等等。我们可以使用一些指令来修改 CPU 的**当前特权级**。而当当前特权级不足以执行特权指令或访问一些寄存器时，CPU 会通过某种方式告诉我们。

OpenSBI 所做的一件事情就是把 CPU 从 M Mode 切换到 S Mode，接着跳转到一个固定地址 0x80200000，开始执行内核代码。

> **[info] RISC-V 的 M Mode**
>
> Machine 模式是 RISC-V 中可以执行的最高权限模式。在机器态下运行的代码对内存、I/O 和一些对于启动和配置系统来说必要的底层功能有着完全的使用权。
>
> **RISC-V 的 S Mode**
>
> Supervisor 模式是支持现代类 Unix 操作系统的权限模式，支持现代类 Unix 操作系统所需要的基于页面的虚拟内存机制是其核心。
>

接着我们要在 `_start` 中设置内核的运行环境了，我们直接来看代码：

{% label %}os/src/asm/entry.asm{% endlabel %}
```assembly
# 操作系统启动时所需的指令以及字段
#
# 我们在 linker.ld 中将程序入口设置为了 _start，因此在这里我们将填充这个标签
# 它将会执行一些必要操作，然后跳转至我们用 rust 编写的入口函数
#
# 关于 RISC-V 下的汇编语言，可以参考 https://github.com/riscv/riscv-asm-manual/blob/master/riscv-asm.md

    .section .text.entry
    .globl _start
# 目前 _start 的功能：将预留的栈空间写入 $sp，然后跳转至 rust_main
_start:
    la sp, bootstacktop
    call rust_main

    # 回忆：bss 段是 ELF 文件中只记录长度，而全部初始化为 0 的一段内存空间
    # 这里声明字段 .bss.stack 作为操作系统启动时的栈
    .section .bss.stack
    .global bootstack
bootstack:
    .space 4096 * 4
    .global bootstacktop
bootstacktop:
    # 栈结尾
```

可以看到之前未被定义的 .bss.stack 段出现了，我们只是在这里分配了一块 $$4096\times{4}\text{\ Bytes}=16 \text{\ KBytes}$$ 的内存作为启动时内核的栈。之前的 .text.entry 也出现了，也就是我们将 `_start` 函数放在了 .text 段的开头。

我们看看 `_start` 里面做了什么：

1. 修改栈指针寄存器 `sp` 为 .bss.stack 段的结束地址，由于栈是从高地址往低地址增长，所以高地址是初始的栈顶；
2. 使用 `call` 指令跳转到 `rust_main` 。这意味着我们的内核运行环境设置完成了，正式进入内核。

我们将 `os/src/main.rs` 里面的 `_start` 函数删除，并换成 `rust_main` ：

{% label %}os/src/main.rs{% endlabel %}
```rust
//! # 全局属性
//! - `#![no_std]`  
//!   禁用标准库
#![no_std]
//!
//! - `#![no_main]`  
//!   不使用 `main` 函数等全部 Rust-level 入口点来作为程序入口
#![no_main]
//!
//! - `#![feature(global_asm)]`  
//!   内嵌整个汇编文件
#![feature(global_asm)]

// 汇编编写的程序入口，具体见该文件
global_asm!(include_str!("asm/entry.asm"));

use core::panic::PanicInfo;

/// 当 panic 发生时会调用该函数
/// 我们暂时将它的实现为一个死循环
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

/// Rust 的入口函数
///
/// 在 `_start` 为我们进行了一系列准备之后，这是第一个被调用的 Rust 函数
#[no_mangle]
pub extern "C" fn rust_main() -> ! {
    loop {}
}
```

到现在为止我们终于将一切都准备好了，接下来就要配合 OpenSBI 运行我们的内核！