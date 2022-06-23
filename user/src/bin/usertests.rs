#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

// not in SUCC_TESTS & FAIL_TESTS
// count_lines, infloop, user_shell, usertests

// item of TESTS : app_name(argv_0), argv_1, argv_2, argv_3, exit_code
static SUCC_TESTS: &[(&str, &str, &str, &str, i32)] = &[
    ("exit\0", "\0", "\0", "\0", 0),
    ("fantastic_text\0", "\0", "\0", "\0", 0),
    ("forktest_simple\0", "\0", "\0", "\0", 0),
    ("forktest\0", "\0", "\0", "\0", 0),
    ("forktest2\0", "\0", "\0", "\0", 0),
    ("forktree\0", "\0", "\0", "\0", 0),
    ("hello_world\0", "\0", "\0", "\0", 0),
    ("matrix\0", "\0", "\0", "\0", 0),
    ("sleep_simple\0", "\0", "\0", "\0", 0),
    ("sleep\0", "\0", "\0", "\0", 0),
    ("yield\0", "\0", "\0", "\0", 0),
];

static FAIL_TESTS: &[(&str, &str, &str, &str, i32)] = &[
    ("stack_overflow\0", "\0", "\0", "\0", -2),
];

use user_lib::{exec, fork, waitpid};

fn run_tests(tests: &[(&str, &str, &str, &str, i32)]) -> i32 {
    let mut pass_num = 0;
    let mut arr: [*const u8; 4] = [
        core::ptr::null::<u8>(),
        core::ptr::null::<u8>(),
        core::ptr::null::<u8>(),
        core::ptr::null::<u8>(),
    ];

    for test in tests {
        println!("Usertests: Running {}", test.0);
        arr[0] = test.0.as_ptr();
        if test.1 != "\0" {
            arr[1] = test.1.as_ptr();
            arr[2] = core::ptr::null::<u8>();
            arr[3] = core::ptr::null::<u8>();
            if test.2 != "\0" {
                arr[2] = test.2.as_ptr();
                arr[3] = core::ptr::null::<u8>();
                if test.3 != "\0" {
                    arr[3] = test.3.as_ptr();
                } else {
                    arr[3] = core::ptr::null::<u8>();
                }
            } else {
                arr[2] = core::ptr::null::<u8>();
                arr[3] = core::ptr::null::<u8>();
            }
        } else {
            arr[1] = core::ptr::null::<u8>();
            arr[2] = core::ptr::null::<u8>();
            arr[3] = core::ptr::null::<u8>();
        }

        let pid = fork();
        if pid == 0 {
            exec(test.0);
            panic!("unreachable!");
        } else {
            let mut exit_code: i32 = Default::default();
            let wait_pid = waitpid(pid as usize, &mut exit_code);
            assert_eq!(pid, wait_pid);
            if exit_code == test.4 {
                // summary apps with  exit_code
                pass_num = pass_num + 1;
            }
            println!(
                "\x1b[32mUsertests: Test {} in Process {} exited with code {}\x1b[0m",
                test.0, pid, exit_code
            );
        }
    }
    pass_num
}

#[no_mangle]
pub fn main() -> i32 {
    let succ_num = run_tests(SUCC_TESTS);
    let err_num = run_tests(FAIL_TESTS);
    if succ_num == SUCC_TESTS.len() as i32 && err_num == FAIL_TESTS.len() as i32 {
        println!(
            "{} of sueecssed apps, {} of failed apps run correctly. \nUsertests passed!",
            SUCC_TESTS.len(),
            FAIL_TESTS.len()
        );
        return 0;
    }
    if succ_num != SUCC_TESTS.len() as i32 {
        println!(
            "all successed app_num is  {} , but only  passed {}",
            SUCC_TESTS.len(),
            succ_num
        );
    }
    if err_num != FAIL_TESTS.len() as i32 {
        println!(
            "all failed app_num is  {} , but only  passed {}",
            FAIL_TESTS.len(),
            err_num
        );
    }
    println!(" Usertests failed!");
    return -1;
}
