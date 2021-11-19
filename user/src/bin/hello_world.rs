#![no_std]
#![no_main]
#![feature(asm)]

#[macro_use]
extern crate user_lib;

/// 正确输出：
/// Hello world from user mode program!

#[no_mangle]
fn main() -> i32 {
    println!("Hello, world from user mode program!");
    0
}
