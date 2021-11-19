#![no_std]
#![no_main]

extern crate core;
#[macro_use]
extern crate user_lib;

use core::slice;
use user_lib::{getpid, mail_read, mail_write};

const BUF_LEN: usize = 256;
const MAIL_MAX: usize = 16;
const BAD_ADDRESS: usize = 0x90000000;

/// 邮箱错误参数测试，输出 mail3 test OK! 就算正确。

#[no_mangle]
fn main() -> i32 {
    let pid = getpid();
    let null = unsafe { slice::from_raw_parts(BAD_ADDRESS as *const _, 10) };
    assert_eq!(mail_write(pid as usize, &null), -1);
    let mut empty = ['a' as u8; 0];
    assert_eq!(mail_write(pid as usize, &empty), 0);
    assert_eq!(mail_read(&mut empty), -1);
    let buffer0 = ['a' as u8; BUF_LEN];
    for _ in 0..MAIL_MAX {
        assert_eq!(mail_write(pid as usize, &buffer0), BUF_LEN as isize);
    }
    assert_eq!(mail_write(pid as usize, &empty), -1);
    assert_eq!(mail_read(&mut empty), 0);
    assert_eq!(mail_write(pid as usize, &empty), -1);
    println!("mail3 test OK!");
    0
}
