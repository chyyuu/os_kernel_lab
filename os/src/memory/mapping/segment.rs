//! 映射类型 [`MapType`] 和映射片段 [`Segment`]

use crate::memory::{address::*, mapping::Flags, range::Range};

/// 映射的类型
#[derive(Copy, Clone, Debug, Eq, PartialEq)]
pub enum MapType {
    /// 线性映射，操作系统使用
    Linear,
    /// 按帧分配映射
    Framed,
}

/// 一个映射片段（对应旧 tutorial 的 `MemoryArea`）
#[derive(Copy, Clone, Debug, Eq, PartialEq)]
pub struct Segment {
    /// 映射类型
    pub map_type: MapType,
    /// 所映射的虚拟地址
    pub range: Range<VirtualAddress>,
    /// 权限标志
    pub flags: Flags,
}

impl Segment {
    /// 遍历对应的物理地址（如果可能）
    pub fn iter_mapped(&self) -> Option<impl Iterator<Item = PhysicalPageNumber>> {
        match self.map_type {
            // 线性映射可以直接将虚拟地址转换
            MapType::Linear => Some(self.page_range().into().iter()),
            // 按帧映射无法直接获得物理地址，需要分配
            MapType::Framed => None,
        }
    }

    /// 将地址相应地上下取整，获得虚拟页号区间
    pub fn page_range(&self) -> Range<VirtualPageNumber> {
        Range::from(
            VirtualPageNumber::floor(self.range.start)..VirtualPageNumber::ceil(self.range.end),
        )
    }
}
