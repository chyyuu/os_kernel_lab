#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::getpid;

/*
辅助测例 打印子进程 pid
*/

#[no_mangle]
pub fn main() -> i32 {
    let pid = getpid();
    println!("Test getpid OK! pid = {}", pid);
    0
}
