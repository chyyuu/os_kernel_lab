#![no_std]
#![no_main]

extern crate user_lib;

#[no_mangle]
pub fn main(_argc: usize, _argv: &[&str]) -> ! {
    loop {}
}
