#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;
extern crate alloc;

use user_lib::{exit, thread_create, waittid, get_time};
use alloc::vec::Vec;

static mut A: usize = 0;
const PER_THREAD: usize = 2000000;
const THREAD_COUNT: usize = 8;

unsafe fn f() -> ! {
    let start = get_time();
    for _ in 0..PER_THREAD {
        let a = &mut A as *mut usize;
        let cur = a.read_volatile();
        a.write_volatile(cur + 1);
    }
    exit((get_time() - start) as i32)
}

#[no_mangle]
pub fn main() -> i32 {
    let mut v = Vec::new();    
    for _ in 0..THREAD_COUNT {
        v.push(thread_create(f as usize) as usize);
    }
    let mut time_cost = Vec::new();
    for tid in v.iter() {
        time_cost.push(waittid(*tid));
    }
    for (i, cost) in time_cost.iter().enumerate() {
        println!("cost of thread#{} is {}ms", i, cost);
    }
    assert_eq!(unsafe { A }, PER_THREAD * THREAD_COUNT);
    0
}
