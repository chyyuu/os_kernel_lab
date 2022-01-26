#![no_std]
#![no_main]
#![allow(clippy::empty_loop)]

extern crate user_lib;

#[no_mangle]
pub fn main(_argc: usize, _argv: &[&str]) -> ! {
    loop {}
}
