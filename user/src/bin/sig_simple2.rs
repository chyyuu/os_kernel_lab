#![no_std]
#![no_main]

extern crate user_lib;

use user_lib::*;

fn func() {
    println!("user_sig_test passed");
    sigreturn();
}

#[no_mangle]
pub fn main() -> i32 {
    let pid = fork();
    if pid == 0 {
        let mut new = SignalAction::default();
        let mut old = SignalAction::default();
        new.handler = func as usize;

        println!("signal_simple2: child sigaction");
        if sigaction(SIGUSR1, Some(&new), Some(&mut old)) < 0 {
            panic!("Sigaction failed!");
        }
        sleep(1000);
        println!("signal_simple2: child done");
        exit(0);
    } else if pid > 0 {
        println!("signal_simple2: parent kill child");
        sleep(500);
        if kill(pid as usize, SIGUSR1) < 0 {
            println!("Kill failed!");
            exit(1);
        }
        println!("signal_simple2: parent wait child");
        let mut exit_code = 0;
        waitpid(pid as usize, &mut exit_code);
        println!("signal_simple2: parent Done");
        exit(0);
    }

    0
}
