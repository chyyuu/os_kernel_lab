#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::yield_;

/*
理想结果：三个程序交替输出 ABC
*/

const WIDTH: usize = 10;
const HEIGHT: usize = 5;

#[no_mangle]
#[no_mangle]
fn main() -> i32 {
    for i in 0..HEIGHT {
        let buf = ['C' as u8; WIDTH];
        println!(
            "{} [{}/{}]",
            core::str::from_utf8(&buf).unwrap(),
            i + 1,
            HEIGHT
        );
        yield_();
    }
    println!("Test write C OK!");
    0
}
