//! [`PageRange`] 的映射记录

use crate::memory::{
    address::*,
    frame::{FrameTracker, FRAME_ALLOCATOR},
    mapping::{Flags, Range},
    MemoryResult,
};
use alloc::{sync::Arc, vec::Vec};

/// 一个映射片段（对应旧 tutorial 的 `MemoryArea`）
///
/// 保存了映射区域、所映射的物理帧。（不包括用于页表的帧）
pub enum Segment {
    Linear {
        /// 所映射的虚拟地址
        page_range: Range<VirtualPageNumber>,
        /// 权限标志
        flags: Flags,
    },
    Framed {
        /// 所映射的虚拟地址
        page_range: Range<VirtualPageNumber>,
        /// 相对应虚拟地址的物理帧
        ///
        /// 因为同一个帧可以被多个线程映射，所以使用 [`Arc`]。
        frames: Vec<Arc<FrameTracker>>,
        /// 权限标志
        flags: Flags,
    },
}

impl Segment {
    /// 返回页面数量
    pub fn len(&self) -> usize {
        match self {
            Self::Linear { page_range, .. } => page_range.len(),
            Self::Framed { page_range, .. } => page_range.len(),
        }
    }

    /// 如果需要分配帧，则进行分配
    pub fn alloc_frames(&mut self) -> MemoryResult<()> {
        // 如果是按帧分配（Framed），需要对每一个页面分配一个帧
        if let Self::Framed {
            page_range, frames, ..
        } = self
        {
            for _ in page_range.iter() {
                frames.push(Arc::new(FRAME_ALLOCATOR.lock().alloc()?));
            }
        }
        Ok(())
    }

    /// 遍历所有映射关系
    ///
    /// 返回 ([`VirtualPageNumber`], [`PhysicalPageNumber`]) tuple 的迭代器
    ///
    /// 生命周期声明 `'a` 表示返回的迭代器不能在 `&self` 脱离 scope 后使用
    pub fn iter<'a>(
        &'a self,
    ) -> impl Iterator<Item = (VirtualPageNumber, PhysicalPageNumber, Flags)> + 'a {
        SegmentIterator {
            segment: &self,
            index: 0,
        }
    }
}

pub struct SegmentIterator<'a> {
    segment: &'a Segment,
    index: usize,
}

impl<'a> Iterator for SegmentIterator<'a> {
    type Item = (VirtualPageNumber, PhysicalPageNumber, Flags);
    fn next(&mut self) -> Option<Self::Item> {
        if self.index >= self.segment.len() {
            None
        } else {
            let tuple = match self.segment {
                Segment::Linear { page_range, flags } => (
                    page_range.get(self.index),
                    PhysicalPageNumber::from(page_range.get(self.index)),
                    *flags,
                ),
                Segment::Framed {
                    page_range,
                    frames,
                    flags,
                } => (
                    page_range.get(self.index),
                    frames[self.index].page_number(),
                    *flags,
                ),
            };
            self.index += 1;
            Some(tuple)
        }
    }
}
