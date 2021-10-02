#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;
extern crate alloc;

use user_lib::{exit, thread_create, waittid};
use alloc::vec::Vec;

static mut A: usize = 0;
const PER_THREAD: usize = 10000000;
const THREAD_COUNT: usize = 50;

unsafe fn f() -> ! {
    for _ in 0..PER_THREAD {
        let a = &mut A as *mut usize;
        let cur = a.read_volatile();
        a.write_volatile(cur + 1);
    }
    exit(0)
}

#[no_mangle]
pub fn main() -> i32 {
    let mut v = Vec::new();    
    for _ in 0..THREAD_COUNT {
        v.push(thread_create(f as usize) as usize);
    }
    for tid in v.iter() {
        waittid(*tid);
    }
    assert_eq!(unsafe { A }, PER_THREAD * THREAD_COUNT);
    println!("total = {}", unsafe { A });
    0
}
