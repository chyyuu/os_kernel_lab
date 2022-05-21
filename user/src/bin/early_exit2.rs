#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;
extern crate alloc;

use user_lib::{exit, thread_create, sleep};

pub fn thread_a() -> ! {
    println!("into thread_a");
    sleep(1000);
    // the following message cannot be seen since the main thread has exited before
    println!("exit thread_a");
    exit(1)
}

#[no_mangle]
pub fn main() -> i32 {
    thread_create(thread_a as usize, 0);
    sleep(100);
    println!("main thread exited.");
    exit(0)
}
