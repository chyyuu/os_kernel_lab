#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;
extern crate alloc;

use alloc::{fmt::format, string::String, vec::Vec};
use user_lib::{close, get_time, gettid, open, write, OpenFlags};
use user_lib::{exit, thread_create, waittid};

fn worker(size_kib: usize) {
    let mut buffer = [0u8; 1024]; // 1KiB
    for (i, ch) in buffer.iter_mut().enumerate() {
        *ch = i as u8;
    }
    let filename = format(format_args!("testf{}\0", gettid()));
    let f = open(filename.as_str(), OpenFlags::CREATE | OpenFlags::WRONLY);
    if f < 0 {
        panic!("Open test file failed!");
    }
    let f = f as usize;
    for _ in 0..size_kib {
        write(f, &buffer);
    }
    close(f);
    exit(0)
}

#[no_mangle]
pub fn main(argc: usize, argv: &[&str]) -> i32 {
    assert_eq!(argc, 2, "wrong argument");
    let size_mb = 1usize;
    let size_kb = size_mb << 10;
    let workers = argv[1].parse::<usize>().expect("wrong argument");
    assert!(workers >= 1 && size_kb % workers == 0, "wrong argument");

    let start = get_time();

    let mut v = Vec::new();
    let size_mb = 1usize;
    for _ in 0..workers {
        v.push(thread_create(worker as usize, size_kb / workers));
    }
    for tid in v.iter() {
        assert_eq!(0, waittid(*tid as usize));
    }

    let time_ms = (get_time() - start) as usize;
    let speed_kbs = size_kb * 1000 / time_ms;
    println!(
        "{}MiB written by {} threads, time cost = {}ms, write speed = {}KiB/s",
        size_mb, workers, time_ms, speed_kbs
    );
    0
}
