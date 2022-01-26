#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

static TESTS: &[&str] = &[
    "exit\0",
    "fantastic_text\0",
    "forktest\0",
    "forktest2\0",
    "forktest_simple\0",
    "hello_world\0",
    "matrix\0",
    "sleep\0",
    "sleep_simple\0",
    "stack_overflow\0",
    "yield\0",
];

use user_lib::{exec, fork, waitpid};

#[no_mangle]
pub fn main() -> i32 {
    for test in TESTS {
        println!("Usertests: Running {}", test);
        let pid = fork();
        if pid == 0 {
            exec(*test, &[core::ptr::null::<u8>()]);
            panic!("unreachable!");
        } else {
            let mut exit_code: i32 = Default::default();
            let wait_pid = waitpid(pid as usize, &mut exit_code);
            assert_eq!(pid, wait_pid);
            println!(
                "\x1b[32mUsertests: Test {} in Process {} exited with code {}\x1b[0m",
                test, pid, exit_code
            );
        }
    }
    println!("Usertests passed!");
    0
}
