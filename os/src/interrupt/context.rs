//! 保存现场所用的 struct [`Context`]

use crate::memory::*;
use core::fmt;
use core::mem::zeroed;
use riscv::register::sstatus::{self, Sstatus, SPP::*};

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
pub struct Context {
    /// 通用寄存器
    pub x: [usize; 32],
    /// 保存诸多状态位的特权态寄存器
    pub sstatus: Sstatus,
    /// 保存中断地址的特权态寄存器
    pub sepc: usize,
}

/// 创建一个用 0 初始化的 Context
///
/// 这里使用 [`core::mem::zeroed()`] 来强行用全 0 初始化。
/// 因为在一些类型中，0 数值可能不合法（例如引用），所以 [`zeroed()`] 是 unsafe 的
impl Default for Context {
    fn default() -> Self {
        unsafe { zeroed() }
    }
}

/// 格式化输出
///
/// # Example
///
/// ```rust
/// println!("{:x?}", Context);   // {:x?} 表示用十六进制打印其中的数值
/// ```
impl fmt::Debug for Context {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        f.debug_struct("Context")
            .field("registers", &self.x)
            .field("sstatus", &self.sstatus)
            .field("sepc", &self.sepc)
            .finish()
    }
}

impl Context {
    /// 获取栈指针
    pub fn sp(&self) -> usize {
        self.x[2]
    }

    /// 设置栈指针
    pub fn set_sp(&mut self, value: usize) -> &mut Self {
        self.x[2] = value;
        self
    }

    /// 按照函数调用规则写入参数
    ///
    /// 没有考虑一些特殊情况，例如超过 8 个参数，或 struct 空间展开
    pub fn set_arguments(&mut self, arguments: &[usize]) -> &mut Self {
        assert!(arguments.len() <= 8);
        self.x[10..(10 + arguments.len())].copy_from_slice(arguments);
        self
    }

    /// 为线程构建初始 `Context`
    pub fn new(
        stack_top: usize,
        entry_point: usize,
        arguments: Option<&[usize]>,
        is_user: bool,
    ) -> Self {
        let mut context = Self::default();

        // 设置栈顶指针
        context.set_sp(stack_top);
        // 设置初始参数
        if let Some(args) = arguments {
            context.set_arguments(args);
        }
        // 设置入口地址
        context.sepc = entry_point;

        // 设置 sstatus
        context.sstatus = sstatus::read();
        if is_user {
            context.sstatus.set_spp(User);
        } else {
            context.sstatus.set_spp(Supervisor);
        }
        // 这样设置 SPIE 和 SIE 位，使得替换 sstatus 后关闭中断，
        // 而在 sret 到用户线程时开启中断。详见 SPIE 和 SIE 的定义
        context.sstatus.set_spie(true);
        context.sstatus.set_sie(false);

        context
    }
}
