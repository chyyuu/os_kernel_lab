#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::{fork, wait, get_time, getpid, exit, yield_,};

static NUM: usize = 13;

#[no_mangle]
pub fn main() -> i32 {
    for _ in 0..NUM {
        let pid = fork();
        if pid == 0 {
            let current_time = get_time();
            let sleep_length = (current_time as i32 as isize) * (current_time as i32 as isize) % 1000 + 1000;
            println!("Subprocess {} sleep for {} ms", getpid(), sleep_length);
            while get_time() < current_time + sleep_length {
                yield_();
            }
            println!("Subprocess {} OK!", getpid());
            exit(0);
        }
    }

    let mut xstate: i32 = 0;
    for _ in 0..NUM {
        assert!(wait(&mut xstate) > 0);
        assert_eq!(xstate, 0);
    }
    assert!(wait(&mut xstate) < 0);
    println!("r_forktest2 test passed!");
    0
}