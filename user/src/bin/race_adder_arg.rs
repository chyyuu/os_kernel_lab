#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;
extern crate alloc;

use crate::alloc::string::ToString;
use alloc::vec::Vec;
use user_lib::{exit, get_time, thread_create, waittid};

static mut A: usize = 0;
const PER_THREAD: usize = 10000;
const THREAD_COUNT: usize = 16;

unsafe fn f() -> ! {
    let mut t = 2usize;
    for _ in 0..PER_THREAD {
        let a = &mut A as *mut usize;
        let cur = a.read_volatile();
        for _ in 0..500 {
            t = t * t % 10007;
        }
        a.write_volatile(cur + 1);
    }
    exit(t as i32)
}

#[no_mangle]
pub fn main(argc: usize, argv: &[&str]) -> i32 {
    let mut thread_count = THREAD_COUNT;
    if argc == 2 {
        thread_count = argv[1].to_string().parse::<usize>().unwrap();
    } else if argc != 1 {
        println!("ERROR in argv");
        exit(-1);
    }

    let start = get_time();
    let mut v = Vec::new();
    for _ in 0..thread_count {
        v.push(thread_create(f as usize, 0) as usize);
    }
    for tid in v.into_iter() {
        waittid(tid);
    }
    println!("time cost is {}ms", get_time() - start);
    assert_eq!(unsafe { A }, PER_THREAD * thread_count);
    0
}
