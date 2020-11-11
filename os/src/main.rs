#![no_std]
#![no_main]
#![feature(global_asm)]

mod lang_items;

global_asm!(include_str!("entry.asm"));

#[no_mangle]
pub fn rust_main() -> ! {
    loop {}
}