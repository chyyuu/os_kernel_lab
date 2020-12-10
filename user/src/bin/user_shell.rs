#![no_std]
#![no_main]

extern crate alloc;

#[macro_use]
extern crate user_lib;

const LF: u8 = 0x0au8;
const CR: u8 = 0x0du8;
const DL: u8 = 0x7fu8;
const BS: u8 = 0x08u8;

use alloc::string::String;
use user_lib::{fork, exec, waitpid, yield_};
use user_lib::console::getchar;

#[no_mangle]
pub fn main() -> i32 {
    println!("Rust user shell");
    let mut line: String = String::new();
    print!(">> ");
    loop {
        let c = getchar();
        match c {
            LF | CR => {
                println!("");
                if !line.is_empty() {
                    line.push('\0');
                    let pid = fork();
                    if pid == 0 {
                        // child process
                        if exec(line.as_str()) == -1 {
                            println!("Command not found!");
                            return 0;
                        }
                        unreachable!();
                    } else {
                        let mut xstate: i32 = 0;
                        let mut exit_pid: isize = 0;
                        loop {
                            exit_pid = waitpid(pid as usize, &mut xstate);
                            if exit_pid == -1 {
                                yield_();
                            } else {
                                assert_eq!(pid, exit_pid);
                                println!("Shell: Process {} exited with code {}", pid, xstate);
                                break;
                            }
                        }
                    }
                    line.clear();
                }
                print!(">> ");
            }
            DL => {
                if !line.is_empty() {
                    print!("{}", BS as char);
                    print!(" ");
                    print!("{}", BS as char);
                    line.pop();
                }
            }
            _ => {
                print!("{}", c as char);
                line.push(c as char);
            }
        }
    }
}