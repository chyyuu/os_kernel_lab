//! It only works on a single CPU!

#![no_std]
#![no_main]
#![feature(core_intrinsics)]

#[macro_use]
extern crate user_lib;
extern crate alloc;

use alloc::vec::Vec;
use user_lib::{exit, get_time, thread_create, waittid, yield_};
use core::sync::atomic::{compiler_fence, Ordering};

static mut A: usize = 0;
static mut FLAG: [bool; 2] = [false; 2];
static mut TURN: usize = 0;
const PER_THREAD_DEFAULT: usize = 2000;
const THREAD_COUNT_DEFAULT: usize = 2;
static mut PER_THREAD: usize = 0;

unsafe fn critical_section(t: &mut usize) {
    let a = &mut A as *mut usize;
    let cur = a.read_volatile();
    for _ in 0..500 {
        *t = (*t) * (*t) % 10007;
    }
    a.write_volatile(cur + 1);
}

unsafe fn lock(id: usize) {
    FLAG[id] = true;
    let j = 1 - id;
    TURN = j;
    // Tell the compiler not to reorder memory operations
    // across this fence.
    compiler_fence(Ordering::SeqCst);
    while FLAG[j] && TURN == j {
        yield_();
    }
}

unsafe fn unlock(id: usize) {
    FLAG[id] = false;
}

unsafe fn f(id: usize) -> ! {
    let mut t = 2usize;
    for _iter in 0..PER_THREAD {
        lock(id);
        critical_section(&mut t);
        unlock(id);
    }
    exit(t as i32)
}

#[no_mangle]
pub fn main(argc: usize, argv: &[&str]) -> i32 {
    let mut thread_count = THREAD_COUNT_DEFAULT;
    let mut per_thread = PER_THREAD_DEFAULT;
    if argc >= 2 {
        thread_count = argv[1].parse().unwrap();
        if argc >= 3 {
            per_thread = argv[2].parse().unwrap();
        }
    }
    unsafe { PER_THREAD = per_thread; }

    // uncomment this if you want to check the assembly
    // println!(
    //     "addr: lock={:#x}, unlock={:#x}",
    //     lock as usize,
    //     unlock as usize
    // );

    let start = get_time();
    let mut v = Vec::new();
    assert_eq!(thread_count, 2, "Peterson works when there are only 2 threads.");
    for id in 0..thread_count {
        v.push(thread_create(f as usize, id) as usize);
    }
    let mut time_cost = Vec::new();
    for tid in v.iter() {
        time_cost.push(waittid(*tid));
    }
    println!("time cost is {}ms", get_time() - start);
    assert_eq!(unsafe { A }, unsafe { PER_THREAD } * thread_count);
    0
}
