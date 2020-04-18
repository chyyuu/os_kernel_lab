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

use super::frame::*;
use crate::memory::{address::*, config::*};
use lazy_static::*;
use spin::Mutex;

lazy_static! {
    /// 帧分配器
    pub static ref FRAME_ALLOCATOR: Mutex<FrameAllocator> = Mutex::new(FrameAllocator::new());
}

/// 基于链表的帧分配 / 回收
pub struct FrameAllocator {
    /// 记录空闲帧的链表（虚拟地址）
    free_frame_list_head: *mut Frame,
}

impl FrameAllocator {
    /// 创建对象，其中 \[[`BEGIN_VPN`], [`END_VPN`]) 区间内的帧在其空闲链表中
    pub fn new() -> Self {
        let first_frame_ppn = PhysicalPageNumber::ceil(KERNEL_END_ADDRESS.to_physical_linear());
        let first_frame: &mut Frame =
            unsafe { PhysicalAddress::from(first_frame_ppn).deref_kernel() };
        let allocator = FrameAllocator {
            free_frame_list_head: first_frame,
        };
        // 初始化第一个帧
        first_frame.next = 0 as *mut Frame;
        first_frame.size = END_PPN.0 - first_frame_ppn.0;
        allocator
    }

    /// 获取第一个元素的 &mut 引用
    unsafe fn head_mut(&mut self) -> Option<&mut Frame> {
        if self.free_frame_list_head != 0 as *mut Frame {
            Some(&mut *self.free_frame_list_head)
        } else {
            None
        }
    }

    /// 取链表第一个元素来分配帧
    ///
    /// - 如果第一个元素 `size > 1`，则相应修改 `size` 而保留元素
    /// - 如果没有剩余则返回 `Err`
    pub fn alloc(&mut self) -> Result<FrameTracker, &'static str> {
        unsafe {
            if let Some(head) = self.head_mut() {
                // 如果有元素，获取其地址，将要分配该地址对应的帧
                let frame_address = VirtualAddress::from(head as *mut _).to_physical_linear();
                if head.size > 1 {
                    // 如果其剩余帧数大于 1，则仅取出一个页面
                    // 原本的帧已经被分配，需要将原本的 next 和 size 写到下一个帧中，
                    // 并且相应修改 size 和 self.free_frame_list_head
                    let new_head = &mut *(head as *mut Frame).add(1);
                    new_head.next = head.next;
                    new_head.size = head.size - 1;
                    self.free_frame_list_head = new_head;
                    Ok(FrameTracker(frame_address))
                } else {
                    // 剩余帧数为 1，则从链表中移除
                    self.free_frame_list_head = head.next;
                    Ok(FrameTracker(frame_address))
                }
            } else {
                // 链表已空，返回 `Err`
                Err("no available frame to allocate")
            }
        }
    }

    /// 将被释放的帧添加到空闲链表的头部
    ///
    /// 这个函数会在 [`FrameTracker`] 被 drop 时自动调用，不应在其他地方调用
    pub(super) fn dealloc(&mut self, allocated_frame: &FrameTracker) {
        let frame: &mut Frame = unsafe { allocated_frame.address().deref_kernel() };
        frame.next = self.free_frame_list_head;
        frame.size = 1;
        self.free_frame_list_head = frame;
    }
}

/// 因为页帧的分配和回收只应发生在内核线程，不会产生竞争。
/// 所以这里尽管什么都没有实现，但是告诉编译器这个类型是线程安全的。
unsafe impl Send for FrameAllocator {}
