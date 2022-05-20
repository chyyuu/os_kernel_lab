#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::{exit, fork, getpid, sleep, wait, yield_};

const DEPTH: usize = 4;

fn fork_child(cur: &str, branch: char) {
    let mut next = [0u8; DEPTH + 1];
    let l = cur.len();
    if l >= DEPTH {
        return;
    }
    next[..l].copy_from_slice(cur.as_bytes());
    next[l] = branch as u8;
    if fork() == 0 {
        fork_tree(core::str::from_utf8(&next[..l + 1]).unwrap());
        yield_();
        exit(0);
    }
}

fn fork_tree(cur: &str) {
    println!("pid{}: {}", getpid(), cur);
    fork_child(cur, '0');
    fork_child(cur, '1');
    let mut exit_code: i32 = 0;
    for _ in 0..2 {
        wait(&mut exit_code);
    }
}

#[no_mangle]
pub fn main() -> i32 {
    fork_tree("");
    let mut exit_code: i32 = 0;
    for _ in 0..2 {
        wait(&mut exit_code);
    }
    sleep(3000);
    0
}
