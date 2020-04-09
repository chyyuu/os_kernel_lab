## 接口封装和代码整理

### 使用 OpenSBI 提供的服务

OpenSBI 实际上不仅起到了 bootloader 的作用，还为我们提供了一些服务供我们在编写内核时使用。这层接口称为 SBI（Supervisor Binary Interface），是 S Mode 的 OS 和 M Mode 执行环境之间的标准接口。

参考[OpenSBI 文档](https://github.com/riscv/riscv-sbi-doc/blob/master/riscv-sbi.adoc#legacy-sbi-extension-extension-ids-0x00-through-0x0f) ，我们会发现里面包含了一些以 C 函数格式给出的我们可以调用的接口。

上一节中我们的 `console_putchar` 函数类似于调用下面的接口来实现的：
```c
void sbi_console_putchar(int ch)
```

而实际的过程是这样的：我们通过 ecall 发起系统调用。OpenSBI 会检查发起的系统调用的编号，如果编号在 0-8 之间，则进行处理，否则交由我们自己的中断处理程序处理（暂未实现）。

> 编号在 0-8 之间的系统调用，具体请看 [OpenSBI 文档](https://github.com/riscv/riscv-sbi-doc/blob/master/riscv-sbi.adoc#function-listing-1)

执行 ecall 前需要指定系统调用的编号，传递参数。一般而言，$$a_7$$ 为系统调用编号，$$a_0 , a_1 , a_2$$ 为参数：

```rust
// src/sbi.rs

//! 调用 Machine 层的操作
// 目前还不会用到全部的 SBI 调用，暂时允许未使用的变量或函数
#![allow(unused)]

/// SBI 调用
#[inline(always)]
fn sbi_call(which: usize, arg0: usize, arg1: usize, arg2: usize) -> usize {
    let ret;
    unsafe {
        asm!("ecall"
            : "={x10}" (ret)
            : "{x10}" (arg0), "{x11}" (arg1), "{x12}" (arg2), "{x17}" (which)
            : "memory"
            : "volatile");
    }
    ret
}
```

> **[info] 函数调用与 Calling convention **
>
> 我们知道，编译器将高级语言源代码翻译成汇编代码。对于汇编语言而言，在最简单的编程模型中，所能够利用的只有指令集中提供的指令、各通用寄存器、 CPU 的状态、内存资源。那么，在高级语言中，我们进行一次函数调用，编译器要做哪些工作利用汇编语言来实现这一功能呢？
>
> 显然并不是仅用一条指令跳转到被调用函数开头地址就行了。我们还需要考虑：
>
> - 如何传递参数？
> - 如何传递返回值？
> - 如何保证函数返回后能从我们期望的位置继续执行？
>
> 等更多事项。通常编译器按照某种规范去翻译所有的函数调用，这种规范被称为 [Calling convention](https://en.wikipedia.org/wiki/Calling_convention) 。值得一提的是，为了实现函数调用，我们需要预先分配一块内存作为 **调用栈** ，后面会看到调用栈在函数调用过程中极其重要。你也可以理解为什么第一章刚开始我们就要分配栈了。

对于参数比较少且是基本数据类型的时候，我们从左到右使用寄存器 $$a_0 \sim a_7$$ 就可以完成参数的传递。具体规范可参考 [RISC-V calling convention](https://riscv.org/wp-content/uploads/2015/01/riscv-calling.pdf)。

然而，如这种情况一样，设置寄存器并执行汇编指令，这超出了 Rust 语言的描述能力。然而又与之前 `global_asm!` 大段插入汇编代码不同，我们要把 `u8` 类型的单个字符传给 $$a_0$$ 作为输入参数，这种情况较为强调 Rust 与汇编代码的交互。此时我们通常使用**内联汇编（inline assembly）**。

> **[info] 内联汇编**
>
> Rust 中拓展内联汇编的格式如下：
>
> ```rust
> asm!(assembler template
> 	: /* output operands */
> 	: /* input operands */
> 	: /* clobbered registers list */
> 	: /* option */
> );
> ```
>
> 其中：
>
> - assembler template 给出字符串形式的汇编代码；
> - output operands 以及 input operands 分别表示输出和输入，体现着汇编代码与 Rust 代码的交互。每个输出和输入都是用 "constraint"(expr) 的形式给出的，其中 expr 部分是一个 Rust 表达式作为汇编代码的输入、输出，通常为了简单起见仅用一个变量。而 constraint 则是你用来告诉编译器如何进行参数传递；
> - clobbered registers list 需要给出你在整段汇编代码中，除了用来作为输入、输出的寄存器之外，还曾经显式/隐式的修改过哪些寄存器。由于编译器对于汇编指令所知有限，你必须手动告诉它“我可能会修改这个寄存器”，这样它在使用这个寄存器时就会更加小心；
> - option 是 Rust 语言内联汇编特有的（相对于 C 语言），用来对内联汇编整体进行配置。
<!-- TODO 进一步参考 -->

输出部分，我们将结果保存到变量 `ret` 中，限制条件 `{x10}` 告诉编译器使用寄存器 $$x_{10}$$（即 `a0` 寄存器），前面的 `=` 表明汇编代码会修改该寄存器并作为最后的返回值。一般情况下 output operands 的 constraint 部分前面都要加上 `=` 。

输入部分，我们分别通过寄存器 $$x_{10}(a_0),x_{11}(a_1),x_{12}(a_2),x_{17}(a_7)$$ 传入参数 `arg0`、`arg1`、`arg2` 和 `which` ，其中前三个参数分别代表接口可能所需的三个输入参数，最后一个 `which` 用来区分我们调用的是哪个接口（SBI Extension ID）。这里之所以提供三个输入参数是为了将所有接口囊括进去，对于某些接口有的输入参数是冗余的，比如 `sbi_console_putchar` 由于只需一个输入参数，它就只关心寄存器 $$a_0$$ 的值。

在 clobbered registers list 中，出现了一个 `"memory"` ，这用来告诉编译器汇编代码隐式的修改了在汇编代码中未曾出现的某些寄存器。所以，它也不能认为汇编代码中未出现的寄存器就会在内联汇编前后保持不变了。

在 option 部分出现了 `"volatile"` ，我们可能在很多地方看到过这个单词。不过在内联汇编中，主要意思是告诉编译器，不要将内联汇编代码移动到别的地方去。我们知道，编译器通常会对翻译完的汇编代码进行优化，其中就包括对指令的位置进行调换。像这种情况，调换可能就会产生我们预期之外的结果。谨慎起见，我们针对内联汇编禁用这一优化。

接着利用 `sbi_call` 函数参考 OpenSBI 文档实现对应的接口，顺带也可以把关机函数通过 SBI 接口一并实现：

```rust
// src/sbi.rs

const SBI_SET_TIMER: usize = 0;
const SBI_CONSOLE_PUTCHAR: usize = 1;
const SBI_CONSOLE_GETCHAR: usize = 2;
const SBI_CLEAR_IPI: usize = 3;
const SBI_SEND_IPI: usize = 4;
const SBI_REMOTE_FENCE_I: usize = 5;
const SBI_REMOTE_SFENCE_VMA: usize = 6;
const SBI_REMOTE_SFENCE_VMA_ASID: usize = 7;
const SBI_SHUTDOWN: usize = 8;

/// 向控制台输出一个字符
///
/// 需要注意我们不能直接使用 Rust 中的 char 类型
pub fn console_putchar(c: usize) {
    sbi_call(SBI_CONSOLE_PUTCHAR, c, 0, 0);
}

/// 从控制台中读取一个字符
///
/// 没有读取到字符则返回 -1
pub fn console_getchar() -> usize {
    sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0)
}

/// 调用 SBI_SHUTDOWN 来关闭操作系统（直接退出 QEMU）
pub fn shutdown() -> ! {
    sbi_call(SBI_SHUTDOWN, 0, 0, 0);
    unreachable!()
}
```

现在我们比较深入的理解了 `console_putchar` 到底是怎么一回事。下面我们使用 `console_putchar` 实现格式化输出，为后面的调试提供方便。

### 实现格式化输出

只能使用 `console_putchar` 这种苍白无力的输出手段让人头皮发麻。如果我们能使用 `println!` 宏的话该有多好啊！于是我们就来实现自己的 `print!`宏和 `println!`宏！

我们将这一部分放在 `src/conosle.rs` 中，关于格式化输出，Rust 中提供了一个接口 `core::fmt::Write`，你需要实现函数：

```rust
fn write_str(&mut self, s: &str) -> Result
```

随后我们就可以调用如下函数（会进一步调用`write_str` 实现函数）来进行显示：

```rust
fn write_fmt(mut self: &mut Self, args: Arguments<'_>) -> Result
```

`write_fmt` 函数需要处理 `Arguments` 类封装的输出字符串。而我们已经有现成的 `format_args!` 宏，它可以将模式字符串和参数列表的输入转化为 `Arguments` 类，比如 `format_args!("{} {}", 1, 2)` 。

因此，我们宏的实现思路便为：

- 解析传入参数，转化为 `format_args!` 可接受的输入（事实上原封不动就行了），并通过 `format_args!` 宏得到 `Arguments` 类
- 调用 `write_fmt` 函数输出这个类

而为了调用 `write_fmt` 函数，我们必须实现 `write_str` 函数，而它可用 `console_putchar` 函数来实现。

最后，我们把整个 `print` 和 `println` 宏按照逻辑写出即可，整体逻辑的代码如下：

```rust
// src/console.rs

//! 实现控制台的字符输入和输出
//! 
//! # 格式化输出
//! 
//! [`core::fmt::Write`] trait 包含
//! - 需要实现的 [`write_str`] 方法
//! - 自带实现，但依赖于 [`write_str`] 的 [`write_fmt`] 方法
//! 
//! 我们声明一个类型，为其实现 [`write_str`] 方法后，就可以使用 [`write_fmt`] 来进行格式化输出
//! 
//! [`write_str`]: core::fmt::Write::write_str
//! [`write_fmt`]: core::fmt::Write::write_fmt

use crate::sbi::*;
use core::fmt::{self, Write};

/// 一个 [Zero-Sized Type]，实现 [`core::fmt::Write`] trait 来进行格式化输出
/// 
/// ZST 只可能有一个值（即为空），因此它本身就是一个单件
/// 
/// [Zero-Sized Type]: https://doc.rust-lang.org/nomicon/exotic-sizes.html#zero-sized-types-zsts
struct Stdout;

impl Write for Stdout {
    /// 打印一个字符串
    /// 
    /// 对于每一个字符调用 [`console_putchar`]
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for c in s.chars() {
            console_putchar(c as usize);
        }
        Ok(())
    }
}

/// 打印由 [`core::format_args!`] 格式化后的数据
/// 
/// [`print!`] 和 [`println!`] 宏都将展开成此函数
/// 
/// [`core::format_args!`]: https://doc.rust-lang.org/nightly/core/macro.format_args.html
pub fn print(args: fmt::Arguments) {
    Stdout.write_fmt(args).unwrap();
}

/// 实现类似于标准库中的 `print!` 宏
/// 
/// 使用实现了 [`core::fmt::Write`] trait 的 [`console::Stdout`]
#[macro_export]
macro_rules! print {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        $crate::console::print(format_args!($fmt $(, $($arg)+)?));
    }
}

/// 实现类似于标准库中的 `println!` 宏
/// 
/// 使用实现了 [`core::fmt::Write`] trait 的 [`console::Stdout`]
#[macro_export]
macro_rules! println {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        $crate::console::print(format_args!(concat!($fmt, "\n") $(, $($arg)+)?));
    }
}
```

### 整理 panic 处理模块
最后，我们用刚刚实现的格式化输出和关机的函数，将 `main.rs` 中处理 panic 的语义项抽取并完善到 `panic.rs` 中：

```rust
//! 代替 std 库，实现 panic 和 abort 的功能

use core::panic::PanicInfo;
use crate::sbi::shutdown;

/// 打印 panic 的信息并 [`shutdown`]
///
/// ### `#[panic_handler]` 属性
/// 声明此函数是 panic 的回调
#[panic_handler]
fn panic_handler(info: &PanicInfo) -> ! {
    // `\x1b[??m` 是控制终端字符输出格式的指令，在支持的平台上可以改变文字颜色等等
    // 这里使用错误红
    // 需要全局开启 feature(panic_info_message) 才可以调用 .message() 函数
    // 参考：https://misc.flogisoft.com/bash/tip_colors_and_formatting
    println!("\x1b[1;31mpanic: '{}'\x1b[0m", info.message().unwrap());
    shutdown()
}

/// 终止程序
/// 
/// 调用 [`panic_handler`]
#[no_mangle]
extern "C" fn abort() -> ! {
    panic!("abort()")
}
```

### 检验我们的成果

最后，我们可以 `src/main.rs` 中去掉之前写的 `console_putchar`并调用我们新写的一系列函数，并在 Rust 入口处加入一些简单的输出看一看我们的逻辑是否正确：

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
//! - `#![deny(missing_docs)]`  
//!   任何没有注释的地方都会产生警告：这个属性用来压榨写实验指导的学长，同学可以删掉了
#![warn(missing_docs)]
//! # 一些 unstable 的功能需要在 crate 层级声明后才可以使用
//! - `#![feature(asm)]`  
//!   内嵌汇编
#![feature(asm)]
//!
//! - `#![feature(global_asm)]`  
//!   内嵌整个汇编文件
#![feature(global_asm)]
//!
//! - `#![feature(panic_info_message)]`  
//!   panic! 时，获取其中的信息并打印
#![feature(panic_info_message)]

#[macro_use]
mod console;
mod panic;
mod sbi;

// 汇编编写的程序入口，具体见该文件
global_asm!(include_str!("asm/entry.asm"));

/// Rust 的入口函数
///
/// 在 `_start` 为我们进行了一系列准备之后，这是第一个被调用的 Rust 函数
#[no_mangle]
pub extern "C" fn rust_main() -> ! {
    println!("Hello rCore-Tutorial!");
    panic!("end of rust_main")
}
```

在命令行中输入 `make run`，我们成功看到了 `println` 宏输出的 "Hello rCore-Tutorial!" 和一行红色的 "panic: 'end of rust_main'"！
```