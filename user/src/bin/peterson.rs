#![no_std]
#![no_main]
#![feature(core_intrinsics)]

#[macro_use]
extern crate user_lib;
extern crate alloc;
extern crate core;

use user_lib::{thread_create, waittid, exit, sleep};
use alloc::vec::Vec;
const N: usize = 3;

static mut TURN: usize = 0;
static mut FLAG: [bool; 2] = [false; 2];

fn peterson_enter_critical(id: usize, peer_id: usize) {
    println!("Thread {} try enter", id);
    store!(&FLAG[id], true);
    store!(&TURN, peer_id);
    memory_fence!();
    while load!(&FLAG[peer_id]) && load!(&TURN) == peer_id {
        println!("Thread {} enter fail", id);
        sleep(1);
        println!("Thread {} retry enter", id);
    }
    println!("Thread {} enter", id);
}

fn peterson_exit_critical(id: usize) {
    store!(&FLAG[id], false);
    println!("Thread {} exit", id);
}

pub fn thread_fn(id: usize) -> ! {
    println!("Thread {} init.", id);
    let peer_id: usize = id ^ 1;
    for _ in 0..N {
        peterson_enter_critical(id, peer_id);
        for _ in 0..3 {
            sleep(2);
        }
        peterson_exit_critical(id);
    }
    exit(0)
}

#[no_mangle]
pub fn main() -> i32 {
    let mut v = Vec::new();
    v.push(thread_create(thread_fn as usize, 0));
    v.push(thread_create(thread_fn as usize, 1));
    for tid in v.iter() {
        let exit_code = waittid(*tid as usize);
        println!("thread#{} exited with code {}", tid, exit_code);
    }
    println!("main thread exited.");
    0
}