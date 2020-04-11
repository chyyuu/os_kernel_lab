//! 处理不同种类中断的流程

use super::trap_frame::TrapFrame;
use riscv::register::stvec;

global_asm!(include_str!("../asm/interrupt.asm"));

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
}

/// 中断的处理入口
/// 
/// `interrupt.asm` 首先保存寄存器至 TrapFrame，其作为参数传入此函数  
/// 具体的中断类型需要根据 TrapFram::scause 来推断，然后分别处理
#[no_mangle]
pub fn handle_interrupt(trap_frame: &mut TrapFrame) {
    println!("Interrupt handled!");
    trap_frame.sepc += 2;
}