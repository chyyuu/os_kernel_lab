//! [`PageRange`] 的映射记录

use crate::memory::{
    address::*,
    frame::FrameTracker,
    mapping::{Flags, Range},
};
use alloc::{sync::Arc, vec, vec::Vec};

/// 一个映射片段（对应旧 tutorial 的 `MemoryArea`）
///
/// 保存了映射区域、所映射的物理帧。（不包括用于页表的帧）
pub(super) enum Segment {
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
    /// 创建一个按帧映射的空白片段
    pub(super) fn new_framed(page_range: Range<VirtualPageNumber>, flags: Flags) -> Self {
        Self::Framed {
            page_range,
            frames: vec![],
            flags,
        }
    }
    /// 记录一个被分配的帧
    pub(super) fn add_frame(&mut self, frame: Arc<FrameTracker>) {
        if let Self::Framed { frames, .. } = self {
            frames.push(frame);
        } else {
            unreachable!()
        }
    }
}
