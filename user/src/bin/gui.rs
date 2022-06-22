#![no_std]
#![no_main]

use user_lib::create_desktop;

#[macro_use]
extern crate user_lib;



#[no_mangle]
pub fn main() -> i32 {
    println!("gui");
    create_desktop();
    println!("exit pass.");
    loop{}
    0
}

