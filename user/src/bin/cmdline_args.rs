#![no_std]
#![no_main]

extern crate alloc;

#[macro_use]
extern crate user_lib;

#[no_mangle]
pub fn main(argc: usize, argv: &[&str]) -> i32 {
    println!("argc = {}", argc);
    for i in 0..argc {
        println!("argv[{}] = {}", i, argv[i]);
    }
    0
}