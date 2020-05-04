//! 每个线程的栈 [`Stack`] 以及内核栈 [`KernelStack`]

use super::*;
use crate::memory::*;
use core::mem::{size_of, zeroed};
use lazy_static::*;

/// 栈是一片内存区域，其空间分配在 `Mapping` 中完成
pub struct Stack {
    range: Range<VirtualAddress>,
}

impl From<Range<VirtualAddress>> for Stack {
    fn from(range: Range<VirtualAddress>) -> Self {
        Self { range }
    }
}

impl Stack {
    /// 生成对应的 [`Segment`]
    pub fn get_segment(&self) -> Segment {
        Segment {
            map_type: MapType::Framed,
            page_range: Range::from(
                VirtualPageNumber::floor(self.range.start)..VirtualPageNumber::ceil(self.range.end),
            ),
            flags: Flags::READABLE | Flags::WRITABLE,
        }
    }

    /// 返回栈顶地址
    pub fn top(&self) -> VirtualAddress {
        self.range.end
    }
}

#[repr(align(16))]
#[repr(C)]
pub struct KernelStack([u8; STACK_SIZE]);

lazy_static!{
    pub static ref KERNEL_STACK: KernelStack = KernelStack([0; STACK_SIZE]);
}

impl KernelStack {
    /// 在栈顶加入 TrapFrame 并且返回 sp
    pub fn push_trap_frame(&self, trap_frame: TrapFrame) -> usize {
        let push_address = &self as *const _ as usize + STACK_SIZE - size_of::<TrapFrame>();
        unsafe {
            *(push_address as *mut TrapFrame) = trap_frame;
        }
        push_address
    }
}
