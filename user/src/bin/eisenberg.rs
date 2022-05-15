#![no_std]
#![no_main]
#![feature(core_intrinsics)]

#[macro_use]
extern crate user_lib;
extern crate alloc;
extern crate core;

use user_lib::{thread_create, waittid, exit, sleep};
use alloc::vec::Vec;
use core::sync::atomic::{AtomicUsize, Ordering};

const N: usize = 2;
const THREAD_NUM: usize = 10;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum FlagState {
    Out, Want, In,
}

static mut TURN: usize = 0;
static mut FLAG: [FlagState; THREAD_NUM] = [FlagState::Out; THREAD_NUM];

static GUARD: AtomicUsize = AtomicUsize::new(0);

fn critical_test_enter() {
    assert_eq!(GUARD.fetch_add(1, Ordering::SeqCst), 0); 
}

fn critical_test_claim() {
    assert_eq!(GUARD.load(Ordering::SeqCst), 1);
}

fn critical_test_exit() {
    assert_eq!(GUARD.fetch_sub(1, Ordering::SeqCst), 1); 
}

fn eisenberg_enter_critical(id: usize) {
    /* announce that we want to enter */
    loop {
        println!("Thread[{}] try enter", id);
        vstore!(&FLAG[id], FlagState::Want);
        loop {
            /* check if any with higher priority is `Want` or `In` */
            let mut prior_thread:Option<usize> = None;
            let turn = vload!(&TURN);
            let ring_id = if id < turn { id + THREAD_NUM } else { id };
            // FLAG.iter() may lead to some errors, use for-loop instead
            for i in turn..ring_id {
                if vload!(&FLAG[i % THREAD_NUM]) != FlagState::Out {
                    prior_thread = Some(i % THREAD_NUM);
                    break;
                }
            }
            if prior_thread.is_none() {
                break;
            }
            println!("Thread[{}]: prior thread {} exist, sleep and retry", 
                      id, prior_thread.unwrap());
            sleep(1);
        }
        /* now tentatively claim the resource */
        vstore!(&FLAG[id], FlagState::In);
        /* enforce the order of `claim` and `conflict check`*/
        memory_fence!();
        /* check if anthor thread is also `In`, which imply a conflict*/
        let mut conflict = false;
        for i in 0..THREAD_NUM {
            if i != id && vload!(&FLAG[i]) == FlagState::In {
                conflict = true;
            }
        }
        if !conflict {
            break;
        }
        println!("Thread[{}]: CONFLECT!", id);
        /* no need to sleep */
    }
    /* clain the trun */
    vstore!(&TURN, id);
    println!("Thread[{}] enter", id);
}

fn eisenberg_exit_critical(id: usize) {
    /* find next one who wants to enter and give the turn to it*/
    let mut next = id;
    let ring_id = id + THREAD_NUM;
    for i in (id+1)..ring_id {
        let idx = i % THREAD_NUM;
        if vload!(&FLAG[idx]) == FlagState::Want {
            next = idx;
            break;
        }
    }
    vstore!(&TURN, next);
    /* All done */
    vstore!(&FLAG[id], FlagState::Out);
    println!("Thread[{}] exit, give turn to {}", id, next);
}

pub fn thread_fn(id: usize) -> ! {
    println!("Thread[{}] init.", id);
    for _ in 0..N {
        eisenberg_enter_critical(id);
        critical_test_enter();
        for _ in 0..3 {
            critical_test_claim();
            sleep(2);
        }
        critical_test_exit();
        eisenberg_exit_critical(id);
    }
    exit(0)
}

#[no_mangle]
pub fn main() -> i32 {
    let mut v = Vec::new();
    // TODO: really shuffle
    assert_eq!(THREAD_NUM, 10);
    let shuffle:[usize; 10] = [0, 7, 4, 6, 2, 9, 8, 1, 3, 5];
    for i in 0..THREAD_NUM {
        v.push(thread_create(thread_fn as usize, shuffle[i]));
    }
    for tid in v.iter() {
        let exit_code = waittid(*tid as usize);
        assert_eq!(exit_code, 0, "thread conflict happened!");
        println!("thread#{} exited with code {}", tid, exit_code);
    }
    println!("main thread exited.");
    0
}