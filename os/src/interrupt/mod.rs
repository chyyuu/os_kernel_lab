//! 中断模块
//! 
//! 

use riscv::register::stvec;
mod handler;
mod trap_frame;

/// 初始化中断模块
/// 
/// 把中断入口 `__interrupt` 写入 `stvec` 中，并且开启中断使能
pub fn init() {
    unsafe {
        extern "C" {
            /// `interrupt.asm` 中的中断入口
            fn __interrupt();
        }
        // 使用 Direct 模式，将中断入口设置为 `__interrupt`
        stvec::write(__interrupt as usize, stvec::TrapMode::Direct);
    }
    println!("mod interrupt initialized");
}