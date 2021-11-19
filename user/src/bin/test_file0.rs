#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::{close, open, read, write, OpenFlags};

/// 测试文件基本读写，输出　Test file0 OK! 就算正确。

#[no_mangle]
pub fn main() -> i32 {
    let test_str = "Hello, world!";
    let fname = "fname\0";
    let fd = open(fname, OpenFlags::CREATE | OpenFlags::WRONLY);
    assert!(fd > 0);
    let fd = fd as usize;
    write(fd, test_str.as_bytes());
    close(fd);

    let fd = open(fname, OpenFlags::RDONLY);
    assert!(fd > 0);
    let fd = fd as usize;
    let mut buffer = [0u8; 100];
    let read_len = read(fd, &mut buffer) as usize;
    close(fd);

    assert_eq!(test_str, core::str::from_utf8(&buffer[..read_len]).unwrap(),);
    println!("Test file0 OK!");
    0
}
