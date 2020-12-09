#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::{
    fork,
    wait,
    exec,
    yield_,
};

#[no_mangle]
fn main() -> i32 {
    if fork() == 0 {
        exec("user_shell\0");
    } else {
        loop {
            let mut xstatus: i32 = 0;
            let pid = wait(&mut xstatus);
            if pid == -1 {
                yield_();
                continue;
            }
            println!("[initproc] Release a zombie process!");
        }
    }
    0
}