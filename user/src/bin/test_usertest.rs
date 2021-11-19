#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

static TESTS: &[&str] = &[
    "test_sleep\0",
    "test_sleep1\0",
    "test_mmap0\0",
    "test_mmap1\0",
    "test_mmap2\0",
    "test_mmap3\0",
    "test_unmap\0",
    "test_unmap2\0",
    "test_spawn0\0",
    "test_spawn1\0",
    "test_mail0\0",
    "test_mail1\0",
    "test_mail2\0",
    "test_mail3\0",
];

use user_lib::{exec, fork, waitpid};

/// 辅助测例，运行所有其他测例。

#[no_mangle]
pub fn main() -> i32 {
    for test in TESTS {
        println!("Usertests: Running {}", test);
        let pid = fork();
        if pid == 0 {
            exec(*test);
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
    println!("ch6 Usertests passed!");
    0
}
