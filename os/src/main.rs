#![no_std]
#![no_main]
#![feature(global_asm)]
#![feature(llvm_asm)]
#![feature(panic_info_message)]
#![feature(alloc_error_handler)]

extern crate alloc;

#[macro_use]
mod console;
mod lang_items;
mod sbi;
mod config;
mod mm;

global_asm!(include_str!("entry.asm"));

fn clear_bss() {
    extern "C" {
        fn sbss();
        fn ebss();
    }
    (sbss as usize..ebss as usize).for_each(|a| {
        unsafe { (a as *mut u8).write_volatile(0) }
    });
}

#[no_mangle]
pub extern "C" fn rust_main() -> ! {
    clear_bss(); //in QEMU, this isn't necessary, but in K210 or other real HW, this is necessary.
    println!("Hello, world!");
    mm::init_heap();
    mm::heap_test();
    panic!("Shutdown machine!");
}