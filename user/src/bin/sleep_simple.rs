#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::{get_time, sleep};

#[no_mangle]
pub fn main() -> i32 {
    println!("into sleep test!");
    let start = get_time();
    println!("current time_msec = {}", start);
    sleep(100);
    let end = get_time();
    println!(
        "time_msec = {} after sleeping 100 ticks, delta = {}ms!",
        end,
        end - start
    );
    println!("r_sleep passed!");
    0
}
