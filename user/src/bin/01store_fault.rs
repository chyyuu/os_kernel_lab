#![no_std]
#![no_main]
#![feature(llvm_asm)]

#[macro_use]
extern crate user_lib;

use user_lib::sys_yield;

const WIDTH: usize = 10;
const HEIGHT: usize = 2;

#[no_mangle]
fn main() -> i32 {
    // println!("Into Test store_fault, we will insert an invalid store operation...");
    // println!("Kernel should kill this application!");
    // unsafe { (0x0 as *mut u8).write_volatile(0); }
    println!("Test write_b Begin!");
    for i in 0..HEIGHT {
        for _ in 0..WIDTH { print!("B"); }
        println!(" [{}/{}]", i + 1, HEIGHT);
        sys_yield();
    }
    println!("Test write_b OK!");
    0
}