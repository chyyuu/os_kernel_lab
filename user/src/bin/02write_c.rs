#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::sys_yield;

#[no_mangle]
fn main() -> i32 {
    for _ in 0..3 {
        for _ in 0..10 { print!("C"); }
        println!("");
        sys_yield();
    }
    println!("Test write_c OK!");
    0
}