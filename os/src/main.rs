#![no_std]
#![no_main]
#![feature(llvm_asm)]
#![feature(global_asm)]
#![feature(naked_functions)]

global_asm!(include_str!("entry.asm"));

use core::fmt::{self, Write};
use core::panic::PanicInfo;

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
    s: [usize; 12],
}

#[derive(Copy, Clone)]
#[repr(C)]
pub struct TaskControlBlock {
    pub id: u64,
    pub task_cx_ptr: usize,
}

impl TaskControlBlock {
    pub fn get_task_cx_ptr2(&self) -> *const usize {
        &self.task_cx_ptr as *const usize
    }
}

//fn init_task() -> [TaskControlBlock;2] {
fn init_task() {
    extern "C" {
        fn current();
        fn boot_stack();
        fn task1();
        fn task2();
        fn t1_stack();
        fn t2_stack();
    }
    // let mut tasks = [TaskControlBlock {
    //     task_cx_ptr: 0,
    // }; 2];
    unsafe {
        let mut curr = current as *mut u64;
        core::ptr::write(curr.offset(0) as *mut u64, 1u64);
        println!("curr {:?}", curr);
        let mut tbs0 = task1 as *mut TaskControlBlock;
        let mut tbs1 = task2 as *mut TaskControlBlock;
        (*tbs0).id = 0 as u64;
        (*tbs0).task_cx_ptr = f1 as usize;
        (*tbs1).id = 1 as u64;
        (*tbs1).task_cx_ptr = f2 as usize;
    }
}

global_asm!(include_str!("switch.S"));

extern "C" {
    pub fn __switch(current_task_cx_ptr2: *const usize, next_task_cx_ptr2: *const usize);
}

fn next_task() {
    extern "C" {
        fn current();
        fn task1();
        fn task2();
    }

    unsafe {
        let mut curr = current as *mut u64;

        let mut tbs0 = task1 as *mut TaskControlBlock;
        let mut tbs1 = task2 as *mut TaskControlBlock;

        //let mut tbs = tasks as *mut TaskControlBlock;
        // let mut curr=  current as *mut u64;
        let taskid = core::ptr::read(curr.offset(0) as *mut u64) as u64;
        let current_task_cx_ptr2;
        let next_task_cx_ptr2;
        if taskid == 0 {
            core::ptr::write(curr.offset(0) as *mut u64, 1u64);

            current_task_cx_ptr2 = (*tbs0).get_task_cx_ptr2();
            next_task_cx_ptr2 = (*tbs1).get_task_cx_ptr2();
        } else {
            core::ptr::write(curr.offset(0) as *mut u64, 0u64);

            current_task_cx_ptr2 = (*tbs1).get_task_cx_ptr2() as *const usize;
            next_task_cx_ptr2 = (*tbs0).get_task_cx_ptr2() as *const usize;
        }

        __switch(current_task_cx_ptr2, next_task_cx_ptr2);
    }
}
//-------------------task2----------------------------------
#[no_mangle]
#[link_section = ".text.entry"]
extern "C" fn f2() {
    println!("Hello, world! in f2()");
    sys_exit(2);
}

//-------------------task1----------------------------------
#[no_mangle]
#[link_section = ".text.entry"]
extern "C" fn f1() {
    println!("Hello, world! in f1()");
    sys_exit(1);
}

#[no_mangle]
#[link_section = ".text.entry"]
extern "C" fn rust_main() {
    extern "C" {
        fn current();
        fn task1();
        fn task2();
        fn boot_stack();
        fn t1_stack();
        fn t2_stack();
    }
    println!("Hello, world! in main()");
    //f1();

    init_task();
    println!(
        "current {:#4x}, task1 {:#4x},  task2 {:#4x}, boot_stack {:#4x}, \
            t1_stack {:#4x}, t2_stack {:#4x}",
        current as usize,
        task1 as usize,
        task2 as usize,
        boot_stack as usize,
        t1_stack as usize,
        t2_stack as usize
    );
    unsafe {
        println!("current value: {:#4x}", *(current as usize as *const u64));
    }
    let mut ctx = TaskContext::default();
    let stack_ptr = t1_stack as *mut u8;

    // 1. push f1 addr in new_stack,
    // 2. read f1 addr from t1_stack to task_context.ra,
    // 3. switch to f1
    unsafe {
        core::ptr::write(stack_ptr.offset(STACKSIZE - 8) as *mut u64, f1 as u64);
        ctx.ra = core::ptr::read(stack_ptr.offset(STACKSIZE - 8) as *mut u64) as usize;
        println!("ctx.ra: {:#04x}", ctx.ra);
        println!("f1:     {:#04x}", f1 as u64);
        //switch_(&mut ctx);
    }
    //println!("{:#04x}",ctx.ra);
    //println!("{:#04x}",f1 as u64);
    sys_exit(0);
}
