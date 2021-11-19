#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::{getpid, mail_read, mail_write};

const BUF_LEN: usize = 256;
const MAIL_MAX: usize = 16;

/// 测试邮箱容量，输出 mail1 test OK! 就算正确。

#[no_mangle]
fn main() -> i32 {
    let pid = getpid();
    let buffer0 = ['a' as u8; BUF_LEN];
    for _ in 0..MAIL_MAX {
        assert_eq!(mail_write(pid as usize, &buffer0), BUF_LEN as isize);
    }
    assert_eq!(mail_write(pid as usize, &buffer0), -1);
    let mut buf = [0u8; BUF_LEN];
    assert_eq!(mail_read(&mut buf), BUF_LEN as isize);
    assert_eq!(mail_write(pid as usize, &buffer0), BUF_LEN as isize);
    assert_eq!(mail_write(pid as usize, &buffer0), -1);
    println!("mail1 test OK!");
    0
}
