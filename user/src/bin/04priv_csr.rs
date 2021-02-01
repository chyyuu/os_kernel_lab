#![no_std]
#![no_main]
#![feature(llvm_asm)]

#[macro_use]
extern crate user_lib;

use riscv::register::sstatus::{Sstatus, self, SPP};

#[no_mangle]
fn main() -> i32 {
    println!("Hello, world!");
    let mut sstatus = sstatus::read();
    sstatus.set_spp(SPP::User);

    0
}
