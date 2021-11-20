#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;
use user_lib::{get_time, set_priority};

fn spin_delay() {
    let mut j = true;
    for _ in 0..10 {
        j = !j;
    }
}

// to get enough accuracy, MAX_TIME (the running time of each process) should > 1000 mseconds.
const MAX_TIME: isize = 1000;
fn count_during(prio: isize) -> isize {
    let start_time = get_time();
    let mut acc = 0;
    set_priority(prio);
    loop {
        spin_delay();
        acc += 1;
        if acc % 400 == 0 {
            let time = get_time() - start_time;
            if time > MAX_TIME {
                return acc;
            }
        }
    }
}

#[no_mangle]
pub fn main() -> usize {
    let prio = 7;
    let count = count_during(prio);
    println!("priority = {}, exitcode = {}", prio, count);
    0
}