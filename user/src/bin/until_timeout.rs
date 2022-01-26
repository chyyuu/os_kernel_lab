#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::{exec, fork, get_time, kill, waitpid, waitpid_nb, SignalFlags};

#[no_mangle]
pub fn main(argc: usize, argv: &[&str]) -> i32 {
    assert_eq!(argc, 3, "argc must be 3!");
    let timeout_ms = argv[2]
        .parse::<isize>()
        .expect("Error when parsing timeout!");
    let pid = fork() as usize;
    if pid == 0 {
        if exec(argv[1], &[core::ptr::null::<u8>()]) != 0 {
            println!("Error when executing '{}'", argv[1]);
            return -4;
        }
    } else {
        let start_time = get_time();
        let mut child_exited = false;
        let mut exit_code: i32 = 0;
        loop {
            if get_time() - start_time > timeout_ms {
                break;
            }
            if waitpid_nb(pid, &mut exit_code) as usize == pid {
                child_exited = true;
                println!(
                    "child exited in {}ms, exit_code = {}",
                    get_time() - start_time,
                    exit_code,
                );
            }
        }
        if !child_exited {
            println!("child has run for {}ms, kill it!", timeout_ms);
            kill(pid, SignalFlags::SIGINT.bits());
            assert_eq!(waitpid(pid, &mut exit_code) as usize, pid);
            println!("exit code of the child is {}", exit_code);
        }
    }
    0
}
