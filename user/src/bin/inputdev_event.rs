#![no_std]
#![no_main]

use user_lib::{event_get, DecodeType, Key, KeyType};

#[macro_use]
extern crate user_lib;

#[no_mangle]
pub fn main() -> i32 {
    println!("Input device event test");
    loop {
        if let Some(event) = event_get() {
            if let Some(decoder_type) = event.decode() {
                println!("{:?}", decoder_type);
                if let DecodeType::Key(key, keytype) = decoder_type {
                    if key == Key::Enter && keytype == KeyType::Press {
                        break;
                    }
                }
            }
        }
    }
    0
}