//! [`PageRange`] 的映射记录

use crate::memory::{
    address::*,
    frame::{FrameTracker, FRAME_ALLOCATOR},
    mapping::{Flags, Range},
    MemoryResult,
};
use alloc::{sync::Arc, vec::Vec};

/// 映射的类型
pub enum MapType {
    /// 线性映射，操作系统使用
    Linear,
    /// 按帧分配映射，可能涉及页面置换
    Framed,
}

/// 一个映射片段（对应旧 tutorial 的 `MemoryArea`）
pub struct Segment {
    /// 映射类型
    pub map_type: MapType,
    /// 所映射的虚拟地址
    pub page_range: Range<VirtualPageNumber>,
    /// 权限标志
    pub flags: Flags,
}

impl Segment {
    /// 返回页面数量
    pub fn len(&self) -> usize {
        self.page_range.len()
    }
    /// 返回页号迭代器
    pub fn iter(&self) -> impl Iterator<Item = VirtualPageNumber> {
        self.page_range.iter()
    }
}
