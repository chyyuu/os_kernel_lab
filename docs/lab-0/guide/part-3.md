## 移除运行时环境依赖

### 运行时系统
对于大多数语言，他们都使用了**运行时系统**（Runtime System），这可能导致 `main` 函数并不是实际执行的第一个函数。

以 Rust 语言为例，一个典型的链接了标准库的 Rust 程序会首先跳转到 C 语言运行时环境中的 `crt0`（C Runtime Zero）进入 C 语言运行时环境设置 C 程序运行所需要的环境（如创建堆栈或设置寄存器参数等）。

然后 C 语言运行时环境会跳转到 Rust 运行时环境的入口点（Entry Point）进入 Rust 运行时入口函数继续设置 Rust 运行环境，而这个 Rust 的运行时入口点就是被 `start` 语义项标记的。Rust 运行时环境的入口点结束之后才会调用 `main` 函数进入主程序。

C 语言运行时环境和 Rust 运行时环境都需要标准库支持，我们的程序无法访问。如果覆盖了 `start` 语义项，仍然需要 `crt0`，并不能解决问题。所以需要重写覆盖整个 `crt0` 入口点：

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

use core::panic::PanicInfo;

/// 当 panic 发生时会调用该函数
/// 我们暂时将他的实现为一个死循环
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

/// 覆盖 crt0 中的 _start 函数
/// 我们暂时将它的实现为一个死循环
#[no_mangle]
pub extern "C" fn _start() -> ! {
    loop {}
}
```

我们加上 `#![no_main]` 告诉编译器我们不用常规的入口点。

同时我们实现一个 `_start` 函数来代替 `crt0`，并加上 `#[no_mangle]` 告诉编译器对于此函数禁用编译期间的名称重整（Name Mangling），即确保编译器生成一个名为 `_start` 的函数，而非为了实现函数重载等而生成的形如 `_ZN3blog_os4_start7hb173fedf945531caE` 散列化后的函数名。由于 `_start` 是大多数系统的默认入口点名字，所以我们要确保它不会发生变化。

接着，我们使用 `extern "C"` 描述 `_start` 函数，这是 Rust 中的 FFI （Foreign Function Interface, 语言交互接口）语法，表示此函数是一个 C 函数而非 Rust 函数。由于 `_start` 是作为 C 语言运行时的入口点，看起来合情合理。

由于程序会一直停在 `crt0` 的入口点，我们可以移除没用的 `main` 函数。

### 链接错误

再次 `cargo build` ，我们会看到一大段链接错误。

链接器（Linker）是一个程序，它将生成的目标文件组合为一个可执行文件。不同的操作系统如 Windows、macOS 或 Linux，规定了不同的可执行文件格式，因此也各有自己的链接器，抛出不同的错误；但这些错误的根本原因还是相同的：链接器的默认配置假定程序依赖于 C 语言的运行时环境，但我们的程序并不依赖于它。

为了解决这个错误，我们需要告诉链接器，它不应该包含 C 语言运行时环境。我们可以选择提供特定的链接器参数（Linker Argument），也可以选择编译为裸机目标（Bare Metal Target），我们将沿着后者的思路在后面解决这个问题，即直接编译为裸机目标不链接任何运行时环境。