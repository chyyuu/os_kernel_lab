#![feature(llvm_asm)]
#![feature(naked_functions)]
use std::ptr;

//-------------task-----------------------
const STACKSIZE: isize = 48;

#[derive(Debug, Default)]
#[repr(C)]
pub struct TaskContext {
    ra: usize,
    sp: usize,
}

#[naked]
#[inline(never)]
unsafe fn switch_(new: *const TaskContext) {
    llvm_asm!("
        ld ra, 0(a0)  //TaskContext.ra = f1 fun
        ld sp, 8(a0)  //TaskContext.sp = f1 fun
        ret
        "
    :    :    :    :
    );
}


fn f1() {
    println!("Hello, world! in f1()");
    loop {}
}

fn main() {

    println!("Hello, world! in main()");
    f1();

    let mut ctx = TaskContext::default();
    let mut stack = vec![0_u8; STACKSIZE as usize];

    // 1. push f1 addr in new_stack,
    // 2. read f1 addr from new_stack to task_context.ra,
    // 3. switch to f1
    unsafe {
        println!("f1:     {:#04x}",f1 as u64);
        let stack_bottom = stack.as_mut_ptr().offset(STACKSIZE);
        let stack_ptr = (stack_bottom as usize & !15) as *mut u8;
        ptr::write(stack_ptr.offset(STACKSIZE - 8) as * mut u64, f1 as u64);
        ctx.ra = ptr::read(stack_ptr.offset(STACKSIZE - 8) as * mut u64) as usize;
        ctx.sp = ptr::read(stack_ptr.offset(STACKSIZE - 16) as * mut u64) as usize;
        //println!("ctx.ra: {:#04x}",ctx.ra);

        switch_(&mut ctx);
    }

}
