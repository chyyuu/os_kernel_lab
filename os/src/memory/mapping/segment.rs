//! [`PageRange`] 的映射记录

use crate::memory::{
    address::*,
    frame::{FrameTracker, FRAME_ALLOCATOR},
    mapping::{Flags, Range},
    MemoryResult,
};
use alloc::{sync::Arc, vec::Vec};

/// 映射的类型
#[derive(Debug)]
pub enum MapType {
    /// 线性映射，操作系统使用
    Linear,
    /// 按帧分配映射，可能涉及页面置换
    Framed,
}

/// 一个映射片段（对应旧 tutorial 的 `MemoryArea`）
#[derive(Debug)]
pub struct Segment {
    /// 映射类型
    pub map_type: MapType,
    /// 所映射的虚拟地址
    pub page_range: Range<VirtualPageNumber>,
    /// 权限标志
    pub flags: Flags,
}

/// 方便访问 `page_range` 域中的方法
impl core::ops::Deref for Segment {
    type Target = Range<VirtualPageNumber>;
    fn deref(&self) -> &Self::Target {
        &self.page_range
    }
}