use riscv::register::{
    sstatus::{self, Sstatus},
    scause::Scause,
};

/// 发生中断时，保存的寄存器
/// 
/// 包括所有通用寄存器，以及：
/// - `sstatus`：各种状态位
/// - `sepc`：产生中断的地址
/// - `scause`：中断原因
/// - `stval`：中断的附加信息
/// 
/// ### `#[repr(C)]` 属性
/// 要求 struct 按照 C 语言的规则进行内存分布，否则 Rust 可能按照其他规则进行内存排布
#[repr(C)]
#[derive(Clone, Copy)]
pub struct TrapFrame {
    /// 32 个通用寄存器
    pub x: [usize; 32],
    pub sstatus: Sstatus,
    pub sepc: usize,
    pub scause: Scause,
    pub stval: usize,
}