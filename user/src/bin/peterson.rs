#![no_std]
#![no_main]
#![feature(core_intrinsics)]
#![feature(asm)]

#[macro_use]
extern crate user_lib;
extern crate alloc;
extern crate core;

use user_lib::{thread_create, waittid, exit, sleep};
use core::sync::atomic::{AtomicUsize, Ordering};
use alloc::vec::Vec;
const N: usize = 3;

static mut TURN: usize = 0;
static mut FLAG: [bool; 2] = [false; 2];
static GUARD: AtomicUsize = AtomicUsize::new(0);

fn critical_test_enter() {
    assert_eq!(GUARD.fetch_add(1, Ordering::SeqCst), 0);
}

fn critical_test_claim() {
    assert_eq!(GUARD.load(Ordering::SeqCst), 1);
}

fn critical_test_exit() {
    assert_eq!(GUARD.fetch_sub(1, Ordering::SeqCst), 1); 
}

fn peterson_enter_critical(id: usize, peer_id: usize) {
    println!("Thread[{}] try enter", id);
    vstore!(&FLAG[id], true);
    vstore!(&TURN, peer_id);
    memory_fence!();
    while vload!(&FLAG[peer_id]) && vload!(&TURN) == peer_id {
        println!("Thread[{}] enter fail", id);
        sleep(1);
        println!("Thread[{}] retry enter", id);
    }
    println!("Thread[{}] enter", id);
}

fn peterson_exit_critical(id: usize) {
    vstore!(&FLAG[id], false);
    println!("Thread[{}] exit", id);
}

pub fn thread_fn(id: usize) -> ! {
    println!("Thread[{}] init.", id);
    let peer_id: usize = id ^ 1;
    for _ in 0..N {
        peterson_enter_critical(id, peer_id);
        critical_test_enter();
        for _ in 0..3 {
            critical_test_claim();
            sleep(2);
        }
        critical_test_exit();
        peterson_exit_critical(id);
    }
    exit(0)
}

#[no_mangle]
pub fn main() -> i32 {
    let mut v = Vec::new();
    v.push(thread_create(thread_fn as usize, 0));
    // v.push(thread_create(thread_fn as usize, 1));
    for tid in v.iter() {
        let exit_code = waittid(*tid as usize);
        assert_eq!(exit_code, 0, "thread conflict happened!");
        println!("thread#{} exited with code {}", tid, exit_code);
    }
    println!("main thread exited.");
    0
}