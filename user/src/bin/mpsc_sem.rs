#![no_std]
#![no_main]
#![allow(clippy::println_empty_string)]

#[macro_use]
extern crate user_lib;

extern crate alloc;

use alloc::vec::Vec;
use user_lib::exit;
use user_lib::{semaphore_create, semaphore_down, semaphore_up};
use user_lib::{thread_create, waittid};

const SEM_MUTEX: usize = 0;
const SEM_EMPTY: usize = 1;
const SEM_EXISTED: usize = 2;
const BUFFER_SIZE: usize = 8;
static mut BUFFER: [usize; BUFFER_SIZE] = [0; BUFFER_SIZE];
static mut FRONT: usize = 0;
static mut TAIL: usize = 0;
const PRODUCER_COUNT: usize = 4;
const NUMBER_PER_PRODUCER: usize = 100;

unsafe fn producer(id: *const usize) -> ! {
    let id = *id;
    for _ in 0..NUMBER_PER_PRODUCER {
        semaphore_down(SEM_EMPTY);
        semaphore_down(SEM_MUTEX);
        BUFFER[FRONT] = id;
        FRONT = (FRONT + 1) % BUFFER_SIZE;
        semaphore_up(SEM_MUTEX);
        semaphore_up(SEM_EXISTED);
    }
    exit(0)
}

unsafe fn consumer() -> ! {
    for _ in 0..PRODUCER_COUNT * NUMBER_PER_PRODUCER {
        semaphore_down(SEM_EXISTED);
        semaphore_down(SEM_MUTEX);
        print!("{} ", BUFFER[TAIL]);
        TAIL = (TAIL + 1) % BUFFER_SIZE;
        semaphore_up(SEM_MUTEX);
        semaphore_up(SEM_EMPTY);
    }
    println!("");
    exit(0)
}

#[no_mangle]
pub fn main() -> i32 {
    // create semaphores
    assert_eq!(semaphore_create(1) as usize, SEM_MUTEX);
    assert_eq!(semaphore_create(BUFFER_SIZE) as usize, SEM_EMPTY);
    assert_eq!(semaphore_create(0) as usize, SEM_EXISTED);
    // create threads
    let ids: Vec<_> = (0..PRODUCER_COUNT).collect();
    let mut threads = Vec::new();
    for i in 0..PRODUCER_COUNT {
        threads.push(thread_create(
            producer as usize,
            &ids.as_slice()[i] as *const _ as usize,
        ));
    }
    threads.push(thread_create(consumer as usize, 0));
    // wait for all threads to complete
    for thread in threads.iter() {
        waittid(*thread as usize);
    }
    println!("mpsc_sem passed!");
    0
}
