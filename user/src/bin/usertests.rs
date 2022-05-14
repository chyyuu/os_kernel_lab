#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

static SUCC_TESTS: &[&str] = &[
    "exit\0",
    "fantastic_text\0",
    "forktest\0",
    "forktest2\0",
    "forktest_simple\0",
    "hello_world\0",
    "matrix\0",
    "sleep\0",
    "sleep_simple\0",
    "yield\0",
];

static FAIL_TESTS: &[&str] = &["stack_overflow\0"];

use user_lib::{exec, fork, waitpid};

fn run_tests<F: Fn(i32)>(tests: &[&str], judge: F) {
    for test in tests {
        println!("Usertests: Running {}", test);
        let pid = fork();
        if pid == 0 {
            exec(*test, &[core::ptr::null::<u8>()]);
            panic!("unreachable!");
        } else {
            let mut exit_code: i32 = Default::default();
            let wait_pid = waitpid(pid as usize, &mut exit_code);
            assert_eq!(pid, wait_pid);
            judge(exit_code);
            println!(
                "\x1b[32mUsertests: Test {} in Process {} exited with code {}\x1b[0m",
                test, pid, exit_code
            );
        }
    }
}

#[no_mangle]
pub fn main() -> i32 {
    run_tests(SUCC_TESTS, |code| assert!(code == 0));
    run_tests(FAIL_TESTS, |code| assert!(code != 0));
    println!("Usertests passed!");
    0
}
