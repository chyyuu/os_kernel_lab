//! 保存现场所用的 struct [`TrapFrame`]

use core::fmt;
use core::mem::zeroed;
use riscv::register::sstatus::Sstatus;
use crate::memory::*;

/// 发生中断时，保存的寄存器
///
/// 包括所有通用寄存器，以及：
/// - `sstatus`：各种状态位
/// - `sepc`：产生中断的地址
///
/// ### `#[repr(C)]` 属性
/// 要求 struct 按照 C 语言的规则进行内存分布，否则 Rust 可能按照其他规则进行内存排布
#[repr(C)]
#[derive(Clone, Copy)]
pub struct TrapFrame {
    /// 通用寄存器
    pub x: [usize; 32],
    /// 保存诸多状态位的特权态寄存器
    pub sstatus: Sstatus,
    /// 保存中断地址的特权态寄存器
    pub sepc: usize,
}

/// 创建一个用 0 初始化的 TrapFrame
///
/// 这里使用 [`core::mem::zeroed()`] 来强行用全 0 初始化。
/// 因为在一些类型中，0 数值可能不合法（例如引用），所以 [`zeroed()`] 是 unsafe 的
impl Default for TrapFrame {
    fn default() -> Self {
        unsafe { zeroed() }
    }
}

/// 格式化输出
///
/// # Example
///
/// ```rust
/// println!("{:x?}", TrapFrame);   // {:x?} 表示用十六进制打印其中的数值
/// ```
impl fmt::Debug for TrapFrame {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        f.debug_struct("TrapFrame")
            .field("registers", &self.x)
            .field("sstatus", &self.sstatus)
            .field("sepc", &self.sepc)
            .finish()
    }
}

impl TrapFrame {
    /// 获取 `sp`
    pub fn sp(&self) -> VirtualAddress {
        VirtualAddress::from(self.x[2])
    }
}