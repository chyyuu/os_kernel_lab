#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;
extern crate alloc;

use user_lib::{
    open,
    OpenFlags,
    close,
    read,
};
use alloc::string::String;

#[no_mangle]
pub fn main(argc: usize, argv: &[&str]) -> i32 {
    assert!(argc == 2);
    let fd = open(argv[1], OpenFlags::RDONLY);
    if fd == -1 {
        panic!("Error occured when opening file");
    }
    let fd = fd as usize;
    let mut buf = [0u8; 16];
    let mut s = String::new();
    loop {
        let size = read(fd, &mut buf) as usize;
        if size == 0 { break; }
        s.push_str(core::str::from_utf8(&buf[..size]).unwrap());
    }
    println!("{}", s);
    close(fd);
    0
}