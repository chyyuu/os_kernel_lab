#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;
extern crate alloc;

use alloc::vec::Vec;
use user_lib::{exit, thread_create, waittid};

struct Argument {
    pub ch: char,
    pub rc: i32,
}

fn thread_print(arg: *const Argument) -> ! {
    let arg = unsafe { &*arg };
    for _ in 0..1000 {
        print!("{}", arg.ch);
    }
    exit(arg.rc)
}

#[no_mangle]
pub fn main() -> i32 {
    let mut v = Vec::new();
    let args = [
        Argument { ch: 'a', rc: 1 },
        Argument { ch: 'b', rc: 2 },
        Argument { ch: 'c', rc: 3 },
    ];
    for arg in args.iter() {
        v.push(thread_create(
            thread_print as usize,
            arg as *const _ as usize,
        ));
    }
    for tid in v.iter() {
        let exit_code = waittid(*tid as usize);
        println!("thread#{} exited with code {}", tid, exit_code);
    }
    println!("main thread exited.");
    0
}
