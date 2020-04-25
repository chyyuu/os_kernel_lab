//! 使用链表管理帧
//!
//! 返回的 [`FrameTracker`] 类型代表一个帧，它在被 drop 时会自动将空间补回分配器中。
//!
//! # 为何 [`FrameAllocator`] 只有一个 usize 大小？
//! 这是一个只有在开发操作系统时可以完成的操作：随意访问地址和读写内存。
//! 我们实现的是内存按帧分配的流程，此时我们就可以使用那些还未被分配的帧来记录数据。
//!
//! 因此 [`FrameAllocator`] 记录一个指针指向某一个空闲的帧，
//! 而每个空闲的帧指向再下一个空闲的帧，直到最后一个指向 0 即可。
//! 注意所有地址使用的是虚拟地址（使用线性映射）。
//!
//! 而为了方便初始化，我们再在帧中记录『连续空闲帧数』，那么最初只需要初始化一个帧即可。

// TODO: 修改成分配和释放之间不会互锁

use super::frame::*;
use crate::memory::{MemoryResult, address::*, config::*};
use alloc::{vec, vec::Vec};
use lazy_static::*;
use spin::Mutex;

lazy_static! {
    /// 帧分配器
    pub static ref FRAME_ALLOCATOR: Mutex<FrameAllocator> = Mutex::new(FrameAllocator::new(
        PhysicalPageNumber::ceil(PhysicalAddress::from(*KERNEL_END_ADDRESS)),
        PhysicalPageNumber::floor(MEMORY_END_ADDRESS),
    ));
}

/// 基于链表的帧分配 / 回收
pub struct FrameAllocator {
    /// 记录空闲帧的列表，每一项表示地址、从该地址开始连续多少帧空闲
    free_frame_list: Vec<(PhysicalAddress, usize)>,
}

impl FrameAllocator {
    /// 创建对象，其中 \[[`BEGIN_VPN`], [`END_VPN`]) 区间内的帧在其空闲列表中
    pub fn new(begin_ppn: PhysicalPageNumber, end_ppn: PhysicalPageNumber) -> Self {
        FrameAllocator {
            free_frame_list: vec![(PhysicalAddress::from(begin_ppn), end_ppn - begin_ppn)],
        }
    }

    /// 取列表末尾元素来分配帧
    ///
    /// - 如果末尾元素 `size > 1`，则相应修改 `size` 而保留元素
    /// - 如果没有剩余则返回 `Err`
    pub fn alloc(&mut self) -> MemoryResult<FrameTracker> {
        if let Some((address, page_count)) = self.free_frame_list.pop() {
            // 如果有元素，将要分配该地址对应的帧
            if page_count > 1 {
                // 如果有连续的多个帧空余，则只取出一个，放回剩余部分
                self.free_frame_list
                    .push((address + PAGE_SIZE, page_count - 1));
            }
            Ok(FrameTracker(address))
        } else {
            // 链表已空，返回 `Err`
            Err("no available frame to allocate")
        }
    }

    /// 将被释放的帧添加到空闲列表的尾部
    ///
    /// 这个函数会在 [`FrameTracker`] 被 drop 时自动调用，不应在其他地方调用
    pub(super) fn dealloc(&mut self, frame: &FrameTracker) {
        println!("DROP");
        self.free_frame_list.push((frame.address(), 1));
    }
}