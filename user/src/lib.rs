//! 为各种用户程序提供依赖
//!
//! - 动态内存分配（允许使用 alloc，但总大小固定）
//! - 错误处理（打印信息并退出程序）

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

pub use crate::syscall::*;
use buddy_system_allocator::LockedHeap;
use config::USER_HEAP_SIZE;
use core::alloc::Layout;
use core::panic::PanicInfo;

/// 大小为 [`USER_HEAP_SIZE`] 的堆空间
static mut HEAP_SPACE: [u8; USER_HEAP_SIZE] = [0; USER_HEAP_SIZE];

/// 使用 `buddy_system_allocator` 中的堆
#[global_allocator]
static HEAP: LockedHeap = LockedHeap::empty();

/// 打印 panic 信息并退出用户程序
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

/// 程序入口
#[no_mangle]
pub extern "C" fn _start(_args: isize, _argv: *const u8) -> ! {
    unsafe {
        HEAP.lock()
            .init(HEAP_SPACE.as_ptr() as usize, USER_HEAP_SIZE);
    }
    sys_exit(main())
}

/// 默认的 main 函数
///
/// 设置了弱的 linkage，会被 `bin` 中文件的 `main` 函数取代
#[linkage = "weak"]
#[no_mangle]
fn main() -> isize {
    panic!("no main() linked");
}

/// 终止程序
#[no_mangle]
pub extern "C" fn abort() {
    panic!("abort");
}

/// 内存不足时终止程序
#[lang = "oom"]
fn oom(_: Layout) -> ! {
    panic!("out of memory");
}
