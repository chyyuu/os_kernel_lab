#![no_std]
#![no_main]
#![feature(llvm_asm)]
#![feature(global_asm)]

//global_asm!(include_str!("entry.asm"));

use core::panic::PanicInfo;
use core::fmt::{self, Write};

#[panic_handler]
fn panic(_: &PanicInfo) -> ! {
    loop {}
}

const STDOUT: usize = 1;
const SYSCALL_WRITE: usize = 64;
const SYSCALL_EXIT: usize = 93;


fn syscall(id: usize, args: [usize; 3]) -> isize {
    let mut ret: isize;
    unsafe {
        llvm_asm!("ecall"
            : "={x10}" (ret)
            : "{x10}" (args[0]), "{x11}" (args[1]), "{x12}" (args[2]), "{x17}" (id)
            : "memory"
            : "volatile"
        );
    }
    ret
}

pub fn sys_exit(xstate: i32) -> isize {
    syscall(SYSCALL_EXIT, [xstate as usize, 0, 0])
}

pub fn sys_write(fd: usize, buffer: &[u8]) -> isize {
    syscall(SYSCALL_WRITE, [fd, buffer.as_ptr() as usize, buffer.len()])
}

struct Stdout;

impl Write for Stdout {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        sys_write(STDOUT, s.as_bytes());
        Ok(())
    }
}

pub fn print(args: fmt::Arguments) {
    Stdout.write_fmt(args).unwrap();
}

#[macro_export]
macro_rules! print {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        $crate::console::print(format_args!($fmt $(, $($arg)+)?));
    }
}

#[macro_export]
macro_rules! println {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        print(format_args!(concat!($fmt, "\n") $(, $($arg)+)?));
    }
}


const SBI_SHUTDOWN: usize = 8;

pub fn shutdown() -> ! {
    syscall(SBI_SHUTDOWN, [0, 0, 0]);
    panic!("It should shutdown!");
}

#[no_mangle]
#[link_section = ".text.entry"]
extern "C" fn _start() {
    //println!("Hello, world!");
    //sys_exit(0);
    shutdown();
    //loop{};
}