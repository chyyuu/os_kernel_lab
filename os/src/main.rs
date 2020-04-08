//! `main.rs` 是编译的入口
//!
//! # 关于 `main.rs`
//! 记得我们之前用 `cargo new --bin os` 创建了 os crate？
//! 
//! Rust 中有两种 crate：**bin** 和 **lib**
//! 
//! - **bin** crate 编译为可执行文件，其中应当包含 main.rs，通常它其中会有 `main()` 函数，尽管我们这里没有。
//!   编译器会从 main.rs 出发，递归寻找其所有引用到的代码进行编译，因此我们在这里会声明使用哪些 module。
//! 
//! - **lib** crate 编译为库，其中应当包含 lib.rs。类似地，编译器会从 lib.rs 出发进行编译。
//!
//! ### 没有 `main()`？
//! 
//! 普通情况下，每个编译单元编译后，会进行符号链接，从已编译的文件中寻找 `main` 符号作为程序的入口。
//! 而我们使用了 linker.ld 作为链接脚本，其中声明程序将使用 `_start` 符号作为入口。
//! 
//! `_start` 符号则是在 entry.asm 中使用汇编编写的，其执行后会跳转到此文件中的 [`rust_main`] 函数。
//! [`rust_main`] 将会是第一个被调用的 rust 函数。
//! 
//! [`rust_main`]: fn.rust_main.html

//! # 全局属性
//! - `#![no_std]`  
//!   禁用标准库
#![no_std]
//!
//! - `#![no_main]`  
//!   不使用 `main` 函数来作为程序入口
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
//! - `#![feature(naked_functions)]`  
//!   使用裸函数，不让编译器在函数前后自动添加指令（例如栈上开临时变量），防止干扰我们的内嵌汇编  
//！  如有兴趣可以参考裸函数的 RFC (https://github.com/rust-lang/rfcs/blob/master/text/1201-naked-fns.md)
#![feature(naked_functions)]
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
///
/// ### `extern "C"`
/// Rust 使用自己的一套 ABI，而此语句则要求编译器使用系统 ABI 来编译这个函数，以保证和 `entry.asm` 中的汇编相兼容
///
/// ### `#[no_mangle]` 属性
/// 在 Rust、C++ 等语言中，为了实现函数重载等，编译器会自动将你的函数名进行类似散列的操作
/// 使得即便是具有相同名称的函数，在链接时也有独一无二的符号名称
/// 开启 `no_mangle` 来禁止对函数名进行变化，这样在链接期 `entry.asm` 才能找到名为 `rust_main` 的符号
///
/// ### 返回 `!`（Never 类型）
/// 这个函数显然是不会返回的，因为我们根本就没有向 `$ra` 中写入值
/// 我们的操作系统要么进入死循环，要么通过 SBI 调用直接退出
#[no_mangle]
pub extern "C" fn rust_main() -> ! {
    println!("Hello rCore-Tutorial!");
    panic!("end of rust_main")
}