#![no_std]
#![feature(llvm_asm)]
#![feature(lang_items)]
#![feature(panic_info_message)]
#![feature(linkage)]

pub mod config;
pub mod syscall;

#[macro_use]
pub mod console;

extern crate alloc;

use config::USER_HEAP_SIZE;
use core::alloc::Layout;
use core::panic::PanicInfo;
use buddy_system_allocator::LockedHeap;
use crate::syscall::sys_exit;

static mut HEAP_SPACE: [u8; USER_HEAP_SIZE] = [0; USER_HEAP_SIZE];

#[global_allocator]
static HEAP: LockedHeap = LockedHeap::empty();

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    if let Some(location) = info.location() {
        println!(
            "\x1b[1;31m{}:{}: '{}'\x1b[0m",
            location.file(),
            location.line(),
            info.message().unwrap()
        );
    } else {
        println!("\x1b[1;31mpanic: '{}'\x1b[0m", info.message().unwrap());
    }
    sys_exit(-1);
}

#[no_mangle]
pub extern "C" fn _start(_args: isize, _argv: *const u8) -> ! {
    unsafe {
        HEAP.lock().init(HEAP_SPACE.as_ptr() as usize, USER_HEAP_SIZE);
    }
    sys_exit(main())
}

#[linkage = "weak"]
#[no_mangle]
fn main() -> isize {
    panic!("no main() linked");
}

#[no_mangle]
pub extern fn abort() {
    panic!("abort");
}

#[lang = "oom"]
fn oom(_: Layout) -> ! {
    panic!("out of memory");
}