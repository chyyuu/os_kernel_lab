//! 物理帧的类

use crate::memory::{
    address::*,
    config::PAGE_SIZE,
    frame::allocator::frame_allocator,
};

/// 分配出的物理帧
pub struct AllocatedFrame(pub *const Frame);

impl AllocatedFrame {
    /// 转换为页号
    pub fn page_number(&self) -> PhysicalPageNumber {
        PhysicalPageNumber::from(self.address())
    }
    /// 转换为地址
    pub fn address(&self) -> PhysicalAddress {
        PhysicalAddress::from(self.0)
    }
}

/// 帧在释放时会放回 [`frame_allocator`] 的空闲链表中
impl Drop for AllocatedFrame {
    fn drop(&mut self) {
        frame_allocator.lock().dealloc(self.0);
    }
}

/// 表示一个实际在内存中的物理帧
/// 
/// 如果这个物理帧没有被使用，那么我们就用其前两个 usize 来存储信息
#[repr(C)]
pub struct Frame {
    pub next: *const Frame,
    pub size: usize,
    _data: [u8; PAGE_SIZE - 16],
}