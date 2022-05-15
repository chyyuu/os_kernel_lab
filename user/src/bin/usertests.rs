#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

static SUCC_TESTS: &[&str] = &[
    "matrix\0",
    "exit\0",
    "fantastic_text\0",
    "filetest_simple\0",
    "forktest_simple\0",
    "forktest\0",
    "forktest2\0",
    "forktree\0",
    "hello_world\0",
    "huge_write\0",
    "mpsc_sem\0",
    "phil_din_mutex\0",
    "pipe_large_test\0",
    "pipetest\0",
    "race_adder_atomic\0",
    "race_adder_mutex_blocking\0",
    "race_adder_mutex_spin\0",
    "race_adder_arg\0",
    "sleep_simple\0",
    "sleep\0",
    "sleep_simple\0",
    "sync_sem\0",
    "test_condvar\0",
    "threads_arg\0",
    "threads\0",
    "yield\0",
    "run_pipe_test\0",
];
    
static FAIL_TESTS: &[&str] = &[
    "stack_overflow\0",
    "race_adder_loop\0",
    "priv_csr\0",
    "priv_inst\0",
    "store_fault\0",
    "until_timeout\0",
    "stack_overflow\0",
    "race_adder\0",
    "huge_write_mt\0",
];

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
