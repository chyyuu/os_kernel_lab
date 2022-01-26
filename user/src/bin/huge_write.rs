#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::{close, get_time, open, write, OpenFlags};

#[no_mangle]
pub fn main() -> i32 {
    let mut buffer = [0u8; 1024]; // 1KiB
    for (i, ch) in buffer.iter_mut().enumerate() {
        *ch = i as u8;
    }
    let f = open("testf\0", OpenFlags::CREATE | OpenFlags::WRONLY);
    if f < 0 {
        panic!("Open test file failed!");
    }
    let f = f as usize;
    let start = get_time();
    let size_mb = 1usize;
    for _ in 0..1024 * size_mb {
        write(f, &buffer);
    }
    close(f);
    let time_ms = (get_time() - start) as usize;
    let speed_kbs = size_mb * 1000000 / time_ms;
    println!(
        "{}MiB written, time cost = {}ms, write speed = {}KiB/s",
        size_mb, time_ms, speed_kbs
    );
    0
}
