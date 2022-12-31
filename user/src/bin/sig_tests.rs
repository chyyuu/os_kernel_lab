#![no_std]
#![no_main]

extern crate user_lib;

use user_lib::*;

fn func() {
    println!("func triggered");
    sigreturn();
}

fn user_sig_test_failsignum() {
    let mut new = SignalAction::default();
    let mut old = SignalAction::default();
    new.handler = func as usize;
    if sigaction(50, Some(&new), Some(&mut old)) >= 0 {
        panic!("Wrong sigaction but successed!");
    }
}

fn user_sig_test_kill() {
    let mut new = SignalAction::default();
    let mut old = SignalAction::default();
    new.handler = func as usize;

    if sigaction(SIGUSR1, Some(&new), Some(&mut old)) < 0 {
        panic!("Sigaction failed!");
    }
    if kill(getpid() as usize, SIGUSR1) < 0 {
        println!("Kill failed!");
        exit(1);
    }
}

fn user_sig_test_multiprocsignals() {
    let pid = fork();
    if pid == 0 {
        let mut new = SignalAction::default();
        let mut old = SignalAction::default();
        new.handler = func as usize;
        if sigaction(SIGUSR1, Some(&new), Some(&mut old)) < 0 {
            panic!("Sigaction failed!");
        }
    } else {
        if kill(pid as usize, SIGUSR1) < 0 {
            println!("Kill failed!");
            exit(1);
        }
        let mut exit_code = 0;
        wait(&mut exit_code);
    }
}

fn user_sig_test_restore() {
    let mut new = SignalAction::default();
    let mut old = SignalAction::default();
    let mut old2 = SignalAction::default();
    new.handler = func as usize;

    if sigaction(SIGUSR1, Some(&new), Some(&mut old)) < 0 {
        panic!("Sigaction failed!");
    }

    if sigaction(SIGUSR1, Some(&old), Some(&mut old2)) < 0 {
        panic!("Sigaction failed!");
    }

    if old2.handler != new.handler {
        println!("Restore failed!");
        exit(-1);
    }
}

fn kernel_sig_test_ignore() {
    sigprocmask(SignalFlags::SIGSTOP.bits() as u32);
    if kill(getpid() as usize, SignalFlags::SIGSTOP.bits()) < 0 {
        println!("kill faild\n");
        exit(-1);
    }
}

fn kernel_sig_test_stop_cont() {
    let pid = fork();
    if pid == 0 {
        kill(getpid() as usize, SIGSTOP);
        sleep(500);
        exit(-1);
    } else {
        sleep(1000);
        kill(pid as usize, SIGCONT);
        let mut exit_code = 0;
        wait(&mut exit_code);
    }
}

fn kernel_sig_test_failignorekill() {
    let mut new = SignalAction::default();
    let mut old = SignalAction::default();
    new.handler = func as usize;

    if sigaction(9, Some(&new), Some(&mut old)) >= 0 {
        panic!("Should not set sigaction to kill!");
    }

    if sigaction(
        9,
        Some(&new),
        None) >= 0 {
        panic!("Should not set sigaction to kill!");
    }

    if sigaction(
        9,
        None,
        Some(&mut old)) >= 0 {
        panic!("Should not set sigaction to kill!");
    }

}

fn final_sig_test() {
    let mut new = SignalAction::default();
    let mut old = SignalAction::default();
    new.handler = func as usize;

    let mut pipe_fd = [0usize; 2];
    pipe(&mut pipe_fd);

    let pid = fork();
    if pid == 0 {
        close(pipe_fd[0]);
        if sigaction(SIGUSR1, Some(&new), Some(&mut old)) < 0 {
            panic!("Sigaction failed!");
        }
        write(pipe_fd[1], &[0u8]);
        close(pipe_fd[1]);
        loop {}
    } else {
        close(pipe_fd[1]);
        let mut buf = [0u8; 1];
        assert_eq!(read(pipe_fd[0], &mut buf), 1);
        close(pipe_fd[0]);
        if kill(pid as usize, SIGUSR1) < 0 {
            println!("Kill failed!");
            exit(-1);
        }
        sleep(100);
        kill(pid as usize, SIGKILL);
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
        (
            user_sig_test_multiprocsignals,
            "user_sig_test_multiprocsignals",
        ),
        (user_sig_test_restore, "user_sig_test_restore"),
        (kernel_sig_test_ignore, "kernel_sig_test_ignore"),
        (kernel_sig_test_stop_cont, "kernel_sig_test_stop_cont"),
        (
            kernel_sig_test_failignorekill,
            "kernel_sig_test_failignorekill",
        ),
        (final_sig_test, "final_sig_test"),
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
