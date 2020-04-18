//! [`PageRange`] 的映射记录

use crate::memory::{
    address::*,
    frame::FrameTracker,
    mapping::{Flags, PageRange, PageTableEntry},
};
use alloc::{sync::Arc, vec::Vec};

/// 一个映射片段（对应旧 tutorial 的 `MemoryArea`）
pub(super) enum Segment {
    Linear {
        /// 所映射的虚拟地址
        page_range: PageRange,
        /// 权限标志
        flags: Flags,
    },
    Framed {
        /// 所映射的虚拟地址
        page_range: PageRange,
        /// 相对应虚拟地址的物理帧
        ///
        /// 因为同一个帧可以被多个线程映射，所以使用 [`Arc`]。
        frames: Vec<Arc<FrameTracker>>,
        /// 权限标志
        flags: Flags,
    },
}
