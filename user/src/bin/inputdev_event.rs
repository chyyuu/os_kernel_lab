#![no_std]
#![no_main]

use user_lib::{event_get};

#[macro_use]
extern crate user_lib;

#[no_mangle]
pub fn main() -> i32 {
    println!("Input device event test");
    let mut event=0;
    for _ in 0..3 {
        while event==0 {
            event = event_get();
        }    
        println!("event: {:?}", event);
    }

    0
}