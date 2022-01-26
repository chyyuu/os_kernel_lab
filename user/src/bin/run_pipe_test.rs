#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::{exec, fork, wait};

#[no_mangle]
pub fn main() -> i32 {
    for i in 0..1000 {
        if fork() == 0 {
            exec("pipe_large_test\0", &[core::ptr::null::<u8>()]);
        } else {
            let mut _unused: i32 = 0;
            wait(&mut _unused);
            println!("Iter {} OK.", i);
        }
    }
    0
}
