#![no_std]
#![no_main]
#![feature(global_asm)]
#![feature(llvm_asm)]
#![feature(panic_info_message)]

#[macro_use]
mod console;
mod lang_items;
mod sbi;

global_asm!(include_str!("entry.asm"));
global_asm!(include_str!("link_app.S"));

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
    extern "C" {
        fn app_0_start();
        fn app_0_end();
        fn app_1_start();
        fn app_1_end();
        fn app_2_start();
        fn app_2_end();
    }
    clear_bss(); //in QEMU, this isn't necessary, but in K210 or other real HW, this is necessary.
    println!("Hello, world!");
    println!("app_0 [{:#x}, {:#x})", app_0_start as usize, app_0_end as usize);
    println!("app_1 [{:#x}, {:#x})", app_1_start as usize, app_1_end as usize);
    println!("app_2 [{:#x}, {:#x})", app_2_start as usize, app_2_end as usize);
    panic!("Shutdown machine!");
}