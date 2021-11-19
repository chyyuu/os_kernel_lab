#![no_std]
#![no_main]
#![feature(asm)]

extern crate user_lib;

/// 由于 rustsbi 的问题，该程序无法正确退出
/// > rustsbi 0.2.0-alpha.1 已经修复，可以正常退出

#[no_mangle]
pub fn main() -> ! {
    let mut sstatus: usize;
    unsafe {
        asm!("csrr {}, sstatus", out(reg) sstatus);
    }
    panic!("(-_-) I get sstatus:{:x}\n", sstatus);
}
