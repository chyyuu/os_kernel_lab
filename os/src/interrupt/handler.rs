//! 处理不同种类中断的流程

use super::trap_frame::TrapFrame;

global_asm!(include_str!("../asm/interrupt.asm"));

/// 中断的处理入口
/// 
/// `interrupt.asm` 首先保存寄存器至 TrapFrame，其作为参数传入此函数  
/// 具体的中断类型需要根据 TrapFram::scause 来推断，然后分别处理
#[no_mangle]
pub fn handle_interrupt(trap_frame: &mut TrapFrame) {
    println!("Interrupt handled!");
    trap_frame.sepc += 2;
}