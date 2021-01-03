#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;
use user_lib::{getpid, yield_};

#[no_mangle]
pub fn main() -> i32 {
    println!("Hello, I am process {}.", getpid());
    for i in 0..5 {
        yield_();
        println!("Back in process {}, iteration {}.", getpid(), i);
    }
    println!("yield pass.");
    0
}