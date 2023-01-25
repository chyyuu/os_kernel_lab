#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;
extern crate alloc;

use user_lib::{thread_create, exit, waittid, mutex_create, mutex_lock, mutex_unlock, condvar_create, condvar_signal, condvar_wait};
use alloc::vec::Vec;
use core::cell::UnsafeCell;
use lazy_static::*;

const THREAD_NUM: usize = 3;

struct Barrier {
    mutex_id: usize,
    condvar_id: usize,
    count: UnsafeCell<usize>,
}

impl Barrier {
    pub fn new() -> Self {
        Self {
            mutex_id: mutex_create() as usize,
            condvar_id: condvar_create() as usize,
            count: UnsafeCell::new(0),
        }
    }
    pub fn block(&self) {
        mutex_lock(self.mutex_id);
        let mut count = self.count.get();
        // SAFETY: Here, the accesses of the count is in the
        // critical section protected by the mutex.
        unsafe { *count = *count + 1; } 
        if unsafe { *count } == THREAD_NUM {
            condvar_signal(self.condvar_id);
        } else {
            condvar_wait(self.condvar_id, self.mutex_id);
            condvar_signal(self.condvar_id);
        }
        mutex_unlock(self.mutex_id);
    }
}

unsafe impl Sync for Barrier {}

lazy_static! {
    static ref BARRIER_AB: Barrier = Barrier::new();
    static ref BARRIER_BC: Barrier = Barrier::new();
}

fn thread_fn() {
    for _ in 0..300 { print!("a"); }
    BARRIER_AB.block();
    for _ in 0..300 { print!("b"); }
    BARRIER_BC.block();
    for _ in 0..300 { print!("c"); }
    exit(0)
}

#[no_mangle]
pub fn main() -> i32 {
    let mut v: Vec<isize> = Vec::new();
    for _ in 0..THREAD_NUM {
        v.push(thread_create(thread_fn as usize, 0));
    }
    for tid in v.into_iter() {
        waittid(tid as usize);
    }
    println!("\nOK!");
    0
}
