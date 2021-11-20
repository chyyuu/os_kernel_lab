#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::mmap;

/*
理想结果：程序触发访存异常，被杀死。不输出 error 就算过。
*/

#[no_mangle]
fn main() -> i32 {
    let start: usize = 0x10000000;
    let len: usize = 4096;
    let prot: usize = 1;
    assert_eq!(0, mmap(start, len, prot));
    let addr: *mut u8 = start as *mut u8;
    unsafe {
        *addr = start as u8;
    }
    println!("Should cause error, Test 04_2 fail!");
    0
}
