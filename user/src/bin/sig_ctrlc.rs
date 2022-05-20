#![no_std]
#![no_main]

extern crate alloc;

#[macro_use]
extern crate user_lib;
use user_lib::console::getchar;
use user_lib::*;

const LF: u8 = 0x0au8;
const CR: u8 = 0x0du8;

fn func() {
    println!("signal_handler: caught signal SIGINT, and exit(1)");
    exit(1);
}

#[no_mangle]
pub fn main() -> i32 {
    println!("sig_ctrlc starting....  Press 'ctrl-c' or 'ENTER'  will quit.");

    let mut new = SignalAction::default();
    let old = SignalAction::default();
    new.handler = func as usize;

    println!("sig_ctrlc: sigaction");
    if sigaction(SIGINT, &new, &old) < 0 {
        panic!("Sigaction failed!");
    }
    println!("sig_ctrlc: getchar....");
    loop {
        let c = getchar();

        println!("Got Char  {}", c);
        if c == LF || c == CR {
            return 0;
        }
    }
    println!("sig_ctrlc: Done");
    0
}
