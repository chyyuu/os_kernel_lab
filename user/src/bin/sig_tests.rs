#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

use user_lib::{sigaction, sigprocmask, SignalAction, SignalFlags, fork, exit, wait, kill, getpid, sleep, sigreturn};

fn func() {
    println!("user_sig_test succsess");
    sigreturn();
}

fn func2() {
    loop {
        print!("");
    }
}

fn func3() {
    println!("interrupt");
    sigreturn();
}

fn user_sig_test_failsignum() {
    let mut new = SignalAction::default();
    let old = SignalAction::default();
    new.handler = func as usize;
    if sigaction(50, &new, &old) >= 0 {
        panic!("Wrong sigaction but success!");
    }
}

fn user_sig_test_kill() {
    let mut new = SignalAction::default();
    let old = SignalAction::default();
    new.handler = func as usize;

    if sigaction(10, &new, &old) < 0 {
        panic!("Sigaction failed!");
    }
    if kill(getpid() as usize, 1 << 10) < 0 {
        println!("Kill failed!");
        exit(1);
    }
}

fn user_sig_test_multiprocsignals() {
    let pid= fork();
    if pid == 0{
        let mut new = SignalAction::default();
        let old = SignalAction::default();
        new.handler = func as usize;
        if sigaction(10, &new, &old) < 0 {
            panic!("Sigaction failed!");
        }
    } else {
        if kill(pid as usize, 1 << 10) < 0 {
            println!("Kill failed!");
            exit(1);
        }
        let mut exit_code = 0;
        wait(&mut exit_code);
    }
}

fn user_sig_test_restore() {
    let mut new = SignalAction::default();
    let old = SignalAction::default();
    let old2 = SignalAction::default();
    new.handler = func as usize;

    if sigaction(10, &new, &old) < 0 {
        panic!("Sigaction failed!");
    }

    if sigaction(10, &old, &old2) < 0 {
        panic!("Sigaction failed!");
    }

    if old2.handler != new.handler {
        println!("Restore failed!");
        exit(-1);
    }
}

fn kernel_sig_test_ignore() {
    sigprocmask(SignalFlags::SIGSTOP.bits() as u32);
    if kill(getpid() as usize, SignalFlags::SIGSTOP.bits()) < 0{
        println!("kill faild\n");
        exit(-1);
    }
}

fn kernel_sig_test_stop_cont() {
    let pid= fork();
    if pid == 0 {
        kill(getpid() as usize, SignalFlags::SIGSTOP.bits());
        sleep(1000);
        exit(-1);
    } else {
        sleep(5000);
        kill(pid as usize, SignalFlags::SIGCONT.bits());
        let mut exit_code = 0;
        wait(&mut exit_code);
    }
}

fn kernel_sig_test_failignorekill() {
    let mut new = SignalAction::default();
    let old = SignalAction::default();
    new.handler = func as usize;

    if sigaction(9, &new, &old) >= 0 {
        panic!("Should not set sigaction to kill!");
    }

    if sigaction(9, &new, 0 as *const SignalAction) >= 0 {
        panic!("Should not set sigaction to kill!");
    }

    if sigaction(9, 0 as *const SignalAction, &old) >= 0 {
        panic!("Should not set sigaction to kill!");
    }
}

fn final_sig_test() {
    let mut new = SignalAction::default();
    let old = SignalAction::default();
    new.handler = func2 as usize;

    let mut new2 = SignalAction::default();
    let old2 = SignalAction::default();
    new2.handler = func3 as usize;

    let pid= fork();
    if pid == 0{
        if sigaction(10, &new, &old) < 0 {
            panic!("Sigaction failed!");
        }
        if sigaction(14, &new2, &old2) < 0 {
            panic!("Sigaction failed!");
        }
        if kill(getpid() as usize, 1 << 10) < 0 {
            println!("Kill failed!");
            exit(-1);
        }
    } else {
        sleep(1000);
        if kill(pid as usize, 1 << 14) < 0 {
            println!("Kill failed!");
            exit(-1);
        }
        sleep(1000);
        kill(pid as usize, SignalFlags::SIGKILL.bits());
    }
}


fn run(f: fn()) -> bool {
    let pid = fork();
    if pid == 0 {
        f();
        exit(0);
    } else {
        let mut exit_code: i32 = 0;
        wait(&mut exit_code);
        if exit_code != 0 {
            println!("FAILED!");
        } else {
            println!("OK!");
        }
        exit_code == 0
    }
}

#[no_mangle]
pub fn main() -> i32 {
    let tests: [(fn(), &str); 8] = [
        (user_sig_test_failsignum, "user_sig_test_failsignum"),
        (user_sig_test_kill, "user_sig_test_kill"),
        (user_sig_test_multiprocsignals, "user_sig_test_multiprocsignals"),
        (user_sig_test_restore, "user_sig_test_restore"),
        (kernel_sig_test_ignore, "kernel_sig_test_ignore"),
        (kernel_sig_test_stop_cont, "kernel_sig_test_stop_cont"),
        (kernel_sig_test_failignorekill, "kernel_sig_test_failignorekill"),
        (final_sig_test, "final_sig_test")
    ];
    let mut fail_num = 0;
    for test in tests {
        println!("Testing {}", test.1);
        if !run(test.0) {
            fail_num += 1;
        }
    }
    if fail_num == 0 {
        println!("ALL TESTS PASSED");
        0
    } else {
        println!("SOME TESTS FAILED");
        -1
    }
}
