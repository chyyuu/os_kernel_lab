#![feature(llvm_asm)]
#![feature(naked_functions)]
use std::ptr;

//-------------task-----------------------
const STACKSIZE: isize = 48;

#[derive(Debug, Default)]
#[repr(C)]
pub struct TaskContext {
    ra: usize,
}

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


fn f1() {
    println!("Hello, world! in f1()");
}

fn main() {

    println!("Hello, world! in main()");
    f1();
    // println!("boot_stack {:#4x}, new_stack {:#4x}", boot_stack as usize, new_stack as usize);
    // let mut ctx = TaskContext::default();
    // let stack_ptr = new_stack as *mut u8;

    // 1. push f1 addr in new_stack,
    // 2. read f1 addr from new_stack to task_context.ra,
    // 3. switch to f1
    // unsafe {
    //     ptr::write(stack_ptr.offset(STACKSIZE - 8) as * mut u64, f1 as u64);
    //     ctx.ra = ptr::read(stack_ptr.offset(STACKSIZE - 8) as * mut u64) as usize;
    //     switch_(&mut ctx);
    // }
    // println!("{:#04x}",ctx.ra);
    // println!("{:#04x}",f1 as u64);
}
