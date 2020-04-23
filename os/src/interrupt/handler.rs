//! 处理不同种类中断的流程

use super::timer;
use super::trap_frame::TrapFrame;
use riscv::register::{
    stvec,
    scause::{Trap, Exception, Interrupt},
};

global_asm!(include_str!("../asm/interrupt.asm"));

/// 初始化中断处理
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
    // 可以通过 Debug 来查看发生了什么中断
    // println!("{:x?}", trap_frame.scause.cause());
    match trap_frame.scause.cause() {
        // 断点中断（ebreak）
        Trap::Exception(Exception::Breakpoint) => breakpoint(trap_frame),
        // 时钟中断
        Trap::Interrupt(Interrupt::SupervisorTimer) => supervisor_timer(trap_frame),
        // 其他情况未实现
        _ => unimplemented!("{:x?}", trap_frame),
    }
}

/// 处理 ebreak 断点
/// 
/// 继续执行，其中 `sepc` 增加 2 字节，以跳过当前这条 `ebreak` 指令
fn breakpoint(trap_frame: &mut TrapFrame) {
    println!("Breakpoint at 0x{:x}", trap_frame.sepc);
    trap_frame.sepc += 2;
}

/// 处理时钟中断
/// 
/// 目前只会在 [`timer`] 模块中进行计数
fn supervisor_timer(_: &TrapFrame) {
    timer::tick();
}