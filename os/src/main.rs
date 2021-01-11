#![no_std]
#![no_main]
#![feature(global_asm)]
#![feature(llvm_asm)]
#![feature(panic_info_message)]

#[macro_use]
mod console;
mod lang_items;
mod sbi;
mod config;
mod drivers;

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
    println!("Hello, world begin!");
    drivers::block_device_test();
    println!("Hello, world end!");
    panic!("Shutdown machine!");
}