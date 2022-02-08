#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;
extern crate alloc;

use alloc::vec::Vec;
use user_lib::{exit, thread_create, waittid};
use user_lib::{close, get_time, open, write, OpenFlags};

fn worker(size_kib: usize) {
    let mut buffer = [0u8; 1024]; // 1KiB
    for (i, ch) in buffer.iter_mut().enumerate() {
        *ch = i as u8;
    }
    for _ in 0..size_kib {
        write(3, &buffer); 
    }
    exit(0)
}

#[no_mangle]
pub fn main(argc: usize, argv: &[&str]) -> i32 {
    let f = open("testf\0", OpenFlags::CREATE | OpenFlags::WRONLY);
    if f < 0 {
        panic!("Open test file failed!");
    }
    let f = f as usize;
    assert_eq!(f, 3);
    assert_eq!(argc, 2, "wrong argument");
    let workers = argv[1].parse::<usize>().expect("wrong argument");
    assert!(workers >= 1 && 1024 % workers == 0, "wrong argument");
    
    let start = get_time();
    
    let mut v = Vec::new();
    let size_mb = 1usize;
    for i in 0..workers {
        v.push(thread_create(worker as usize, size_mb * 1024 / workers)); 
    }
    for tid in v.iter() {
        assert_eq!(0, waittid(*tid as usize));
    }
    
    close(f);
    let time_ms = (get_time() - start) as usize;
    let speed_kbs = (size_mb << 20) / time_ms;
    println!(
        "{}MiB written, time cost = {}ms, write speed = {}KiB/s",
        size_mb, time_ms, speed_kbs
    );
    0
}
