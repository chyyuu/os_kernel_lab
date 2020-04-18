//! 物理帧的类

use crate::memory::{
    address::*,
    config::PAGE_SIZE,
    frame::allocator::FRAME_ALLOCATOR,
};

/// 分配出的物理帧
pub struct AllocatedFrame(pub(super) PhysicalAddress);

impl AllocatedFrame {
    /// 帧的物理地址
    pub fn address(&self) -> PhysicalAddress {
        self.0
    }
    /// 帧的物理页号
    pub fn page_number(&self) -> PhysicalPageNumber {
        PhysicalPageNumber::from(self.0)
    }
}

/// 帧在释放时会放回 [`frame_allocator`] 的空闲链表中
impl Drop for AllocatedFrame {
    fn drop(&mut self) {
        FRAME_ALLOCATOR.lock().dealloc(self);
    }
}

/// 表示一个实际在内存中的物理帧
/// 
/// 如果这个物理帧没有被使用，那么我们就用其前两个 usize 来存储信息
#[repr(C)]
pub struct Frame {
    pub(super) next: *const Frame,
    pub(super) size: usize,
    _data: [u8; PAGE_SIZE - 16],
}