#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::yield_;

const WIDTH: usize = 10;
const HEIGHT: usize = 5;

/*
理想结果：三个程序交替输出 ABC
*/

#[no_mangle]
fn main() -> i32 {
    for i in 0..HEIGHT {
        let buf = ['A' as u8; WIDTH];
        println!(
            "{} [{}/{}]",
            core::str::from_utf8(&buf).unwrap(),
            i + 1,
            HEIGHT
        );
        yield_();
    }
    println!("Test write A OK!");
    0
}
