#![no_std]
#![no_main]
#![feature(panic_info_message)]
#![feature(alloc_error_handler)]

extern crate alloc;

#[macro_use]
extern crate bitflags;

#[cfg(feature = "board_k210")]
#[path = "boards/k210.rs"]
mod board;
#[cfg(not(any(feature = "board_k210")))]
#[path = "boards/qemu.rs"]
mod board;

#[macro_use]
mod console;
mod config;
mod drivers;
mod fs;
mod lang_items;
mod mm;
mod sbi;
mod sync;
mod syscall;
mod task;
mod timer;
mod trap;

use core::arch::global_asm;

global_asm!(include_str!("entry.asm"));

fn clear_bss() {
    extern "C" {
        fn sbss();
        fn ebss();
    }
    unsafe {
        core::slice::from_raw_parts_mut(sbss as usize as *mut u8, ebss as usize - sbss as usize)
            .fill(0);
    }
}

#[no_mangle]
pub fn rust_main() -> ! {
    clear_bss();
    println!("[kernel] Hello, world!");
    mm::init();
    mm::remap_test();
    trap::init();
    trap::enable_timer_interrupt();
    timer::set_next_trigger();
    fs::list_apps();
    task::add_initproc();
    task::run_tasks();
    panic!("Unreachable in rust_main!");
}
