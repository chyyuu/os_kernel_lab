#![no_std]
#![no_main]
#![feature(llvm_asm)]
#![feature(global_asm)]
#![feature(naked_functions)]

global_asm!(include_str!("entry.asm"));

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

//-------------task-----------------------
const STACKSIZE: isize = 48;

#[derive(Debug, Default)]
#[repr(C)]
pub struct TaskContext {
    ra: usize,
//    s: [usize; 12],
}

#[no_mangle]
#[link_section=".text.entry"]
#[naked]
#[inline(never)]
unsafe fn switch_(new: *const TaskContext) {
    llvm_asm!("
        ld ra, 0(a0)  //TaskContext.ra = f1 fun
        ret
        "
    :    :    :    :
    );
}

#[no_mangle]
#[link_section=".text.entry"]
extern "C" fn f1() {
    println!("Hello, world! in f1()");
    sys_exit(8);
}

#[no_mangle]
#[link_section=".text.entry"]
extern "C" fn rust_main() {
    extern "C" {
        fn boot_stack();
        fn new_stack();
    }
    println!("Hello, world! in main()");
    //f1();
    println!("boot_stack {:#4x}, new_stack {:#4x}", boot_stack as usize, new_stack as usize);
    let mut ctx = TaskContext::default();
    let stack_ptr = new_stack as *mut u8;

    // 1. push f1 addr in new_stack,
    // 2. read f1 addr from new_stack to task_context.ra,
    // 3. switch to f1
    unsafe {
        core::ptr::write(stack_ptr.offset(STACKSIZE - 8) as * mut u64, f1 as u64);
        ctx.ra = core::ptr::read(stack_ptr.offset(STACKSIZE - 8) as * mut u64) as usize;
        switch_(&mut ctx);
    }
    println!("{:#04x}",ctx.ra);
    println!("{:#04x}",f1 as u64);
    sys_exit(9);
}
