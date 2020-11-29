#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::{sys_get_time, sys_yield};

#[no_mangle]
fn main() -> i32 {
    let current_timer = sys_get_time();
    let wait_for = current_timer + 10000000;
    while sys_get_time() < wait_for {
        sys_yield();
    }
    println!("Test sleep OK!");
    0
}