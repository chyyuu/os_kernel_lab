#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::{exit, fork, mail_read, mail_write, sleep, wait};

const BUF_LEN: usize = 256;

// 双进程邮箱测试，最终输出 mail2 test OK! 就算正确。

#[no_mangle]
fn main() -> i32 {
    let pid = fork();
    if pid == 0 {
        println!("I am child");
        let mut buffer = [0u8; BUF_LEN];
        assert_eq!(mail_read(&mut buffer), -1);
        println!("child read 1 mail fail");
        println!("child sleep 2s");
        sleep(2000 as usize);
        for i in 0..16 {
            let mut buffer = [0u8; BUF_LEN];
            assert_eq!(mail_read(&mut buffer), BUF_LEN as isize);
            assert_eq!(buffer, [i as u8; BUF_LEN]);
        }
        println!("child read 16 mails succeed");
        assert_eq!(mail_read(&mut buffer), -1);
        println!("child read 1 mail fail");
        println!("child sleep 1s");
        sleep(1000 as usize);
        assert_eq!(mail_read(&mut buffer), BUF_LEN as isize);
        assert_eq!(buffer, [16 as u8; BUF_LEN]);
        println!("child read 1 mail succeed");
        println!("child exit");
        exit(0);
    }
    println!("I am father");
    println!("father sleep 1s");
    sleep(1000 as usize);
    for i in 0..16 {
        let buffer = [i as u8; BUF_LEN];
        assert_eq!(mail_write(pid as usize, &buffer), BUF_LEN as isize);
    }
    println!("father wirte 16 mails succeed");
    let buffer = [16 as u8; BUF_LEN];
    assert_eq!(mail_write(pid as usize, &buffer), -1);
    println!("father wirte 1 mail fail");
    println!("father sleep 1.5s");
    sleep(1500 as usize);
    assert_eq!(mail_write(pid as usize, &buffer), BUF_LEN as isize);
    println!("father wirte 1 mail succeed");

    let mut xstate: i32 = -100;
    assert!(wait(&mut xstate) > 0);
    assert_eq!(xstate, 0);
    println!("mail2 test OK!");
    0
}
