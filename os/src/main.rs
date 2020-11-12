#![no_std]
#![no_main]
#![feature(global_asm)]
#![feature(llvm_asm)]

mod lang_items;
mod sbi;
#[macro_use]
mod console;

global_asm!(include_str!("entry.asm"));

#[no_mangle]
pub fn rust_main() -> ! {
    println!("Hello, world!");
    extern "C" {
        fn stext();
        fn etext();
        fn srodata();
        fn erodata();
        fn sdata();
        fn edata();
        fn sbss();
        fn ebss();
        fn boot_stack();
        fn boot_stack_top();
    };
    println!(".text [{:#x}, {:#x})", stext as usize, etext as usize);
    println!(".rodata [{:#x}, {:#x})", srodata as usize, erodata as usize);
    println!(".data [{:#x}, {:#x})", sdata as usize, edata as usize);
    println!("boot_stack [{:#x}, {:#x})", boot_stack as usize, boot_stack_top as usize);
    println!(".bss [{:#x}, {:#x})", sbss as usize, ebss as usize);
    loop {}
}