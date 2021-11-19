#![no_std]
#![no_main]

#[macro_use]
extern crate user_lib;

extern crate alloc;

use alloc::format;
use user_lib::{close, fork, get_time, pipe, read, wait, write};

const LENGTH: usize = 3000;
#[no_mangle]
pub fn main() -> i32 {
    // create pipes
    // parent write to child
    let mut down_pipe_fd = [0usize; 2];
    // child write to parent
    let mut up_pipe_fd = [0usize; 2];
    pipe(&mut down_pipe_fd);
    pipe(&mut up_pipe_fd);
    let mut random_str = [0u8; LENGTH];
    if fork() == 0 {
        // close write end of down pipe
        close(down_pipe_fd[1]);
        // close read end of up pipe
        close(up_pipe_fd[0]);
        assert_eq!(read(down_pipe_fd[0], &mut random_str) as usize, LENGTH);
        close(down_pipe_fd[0]);
        let sum: usize = random_str.iter().map(|v| *v as usize).sum::<usize>();
        println!("sum = {}(child)", sum);
        let sum_str = format!("{}", sum);
        write(up_pipe_fd[1], sum_str.as_bytes());
        close(up_pipe_fd[1]);
        println!("Child process exited!");
        0
    } else {
        // close read end of down pipe
        close(down_pipe_fd[0]);
        // close write end of up pipe
        close(up_pipe_fd[1]);
        // generate a long random string
        for ch in random_str.iter_mut().take(LENGTH) {
            *ch = get_time() as u8;
        }
        // send it
        assert_eq!(
            write(down_pipe_fd[1], &random_str) as usize,
            random_str.len()
        );
        // close write end of down pipe
        close(down_pipe_fd[1]);
        // calculate sum(parent)
        let sum: usize = random_str.iter().map(|v| *v as usize).sum::<usize>();
        println!("sum = {}(parent)", sum);
        // recv sum(child)
        let mut child_result = [0u8; 32];
        let result_len = read(up_pipe_fd[0], &mut child_result) as usize;
        close(up_pipe_fd[0]);
        // check
        assert_eq!(
            sum,
            str::parse::<usize>(core::str::from_utf8(&child_result[..result_len]).unwrap())
                .unwrap()
        );
        let mut _unused: i32 = 0;
        wait(&mut _unused);
        println!("pipe_large_test passed!");
        0
    }
}
