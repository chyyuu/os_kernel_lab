//! 映射类型 [`MapType`] 和映射片段 [`Segment`]

use crate::memory::{
    address::*,
    mapping::{Flags, Range},
};

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

impl Segment {
    /// 遍历对应的物理地址（如果可能）
    pub fn iter_mapped(&self) -> Option<impl Iterator<Item = PhysicalPageNumber>> {
        match self.map_type {
            // 线性映射可以直接将虚拟地址转换
            MapType::Linear => Some(self.iter().map(PhysicalPageNumber::from)),
            // 按帧映射无法直接获得物理地址，需要分配
            MapType::Framed => None,
        }
    }
}

/// 方便访问 `page_range` 域中的方法
impl core::ops::Deref for Segment {
    type Target = Range<VirtualPageNumber>;
    fn deref(&self) -> &Self::Target {
        &self.page_range
    }
}