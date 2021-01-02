#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::sys_yield;

const WIDTH: usize = 10;
const HEIGHT: usize = 5;

#[no_mangle]
fn main() -> i32 {
    println!("Hello, world!\nTest write_a Begin!");

    for i in 0..HEIGHT {
        for _ in 0..WIDTH { print!("A"); }
        println!(" [{}/{}]", i + 1, HEIGHT);
        sys_yield();
    }
    println!("Test write_a OK!");
    0
}
