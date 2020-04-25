//! # 全局属性
//! - `#![no_std]`  
//!   禁用标准库
#![no_std]
//!
//! - `#![no_main]`  
//!   不使用 `main` 函数等全部 Rust-level 入口点来作为程序入口
#![no_main]
//!
//! - `#![deny(missing_docs)]`  
//!   任何没有注释的地方都会产生警告：这个属性用来压榨写实验指导的学长，同学可以删掉了
#![warn(missing_docs)]
//!
//! - `#![feature(alloc_error_handler)]`  
//!   我们使用了一个全局动态内存分配器，以实现原本标准库中的堆内存分配。
//!   而语言要求我们同时实现一个错误回调，这里我们直接 panic
#![feature(alloc_error_handler)]
//! # 一些 unstable 的功能需要在 crate 层级声明后才可以使用
//! - `#![feature(llvm_asm)]`  
//!   内嵌汇编
#![feature(llvm_asm)]
//!
//! - `#![feature(global_asm)]`  
//!   内嵌整个汇编文件
#![feature(global_asm)]
//!
//! - `#![feature(panic_info_message)]`  
//!   panic! 时，获取其中的信息并打印
#![feature(panic_info_message)]

#[macro_use]
mod console;
mod data_structure;
mod file_system;
mod interrupt;
mod memory;
mod panic;
mod process;
mod sbi;

extern crate alloc;
use alloc::sync::Arc;
use msws::*;
use process::*;

// 汇编编写的程序入口，具体见该文件
global_asm!(include_str!("asm/entry.asm"));

/// Rust 的入口函数
///
/// 在 `_start` 为我们进行了一系列准备之后，这是第一个被调用的 Rust 函数
#[no_mangle]
pub extern "C" fn rust_main() -> ! {
    println!("Hello rCore-Tutorial!");

    // 初始化各种模块
    interrupt::init();
    memory::init();

    let kernel_memory = memory::mapping::MemorySet::new_kernel(32).unwrap();
    kernel_memory.activate();
    unsafe {
        PROCESSOR
            .current_thread
            .replace(Arc::new(spin::Mutex::new(Thread {
                thread_id: 0,
                memory_set: kernel_memory,
            })));
    }

    test_framed_paging();
    test_heap();

    unsafe {
        llvm_asm!("ebreak"::::"volatile");
    };

    loop {}
}

/// 测试分配的物理页面和缺页
fn test_framed_paging() {
    let mut rng = Rand::new(seed(0)).unwrap();
    let vpns: alloc::vec::Vec<_> = (0..64).map(|_| rng.rand() as usize & 0x3ffffff).collect();
    for vpn in vpns.iter() {
        current_thread()
            .lock()
            .memory_set
            .test_map_alloc((*vpn).into())
            .unwrap();
    }
    // flush tlb
    current_thread().lock().memory_set.activate();
    for vpn in vpns.iter() {
        for offset in (0..0x1000).step_by(8) {
            let addr = (vpn << 12) + offset;
            unsafe {
                *(addr as *mut usize) = addr;
            }
        }
    }
    for (vpn, offset) in vpns.iter().cycle().zip((0..0x1000).step_by(8)) {
        let addr = (vpn << 12) + offset;
        assert!(unsafe { *(addr as *mut usize) == addr });
    }
    println!("framed mapping test passed");
}

// 从更新的 rcore_tutorial 摘过来
// to be removed
fn test_heap() {
    use alloc::boxed::Box;
    use alloc::vec::Vec;
    let v = Box::new(5);
    assert!(*v == 5);
    let mut vec = Vec::new();
    for i in 0..10000 {
        vec.push(i);
    }
    for i in 0..10000 {
        assert!(vec[i] == i);
    }
    println!("heap test passed");
}
