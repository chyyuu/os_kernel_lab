//! 一个线程中关于内存空间的所有信息 [`MemorySet`]
//!

use crate::memory::{
    address::*,
    config::*,
    frame::FrameTracker,
    mapping::{Flags, MapType, Mapping, Segment},
    range::Range,
    MemoryResult,
};
use alloc::{boxed::Box, vec, vec::Vec};

/// 一个线程所有关于内存空间管理的信息
pub struct MemorySet {
    /// 维护页表和映射关系
    pub mapping: Mapping,
    /// 每个字段
    pub segments: Vec<Segment>,
}

impl MemorySet {
    /// 创建内核重映射
    pub fn new_kernel() -> MemoryResult<MemorySet> {
        // 在 linker.ld 里面标记的各个字段的起始点，均为 4K 对齐
        extern "C" {
            fn text_start();
            fn rodata_start();
            fn data_start();
            fn bss_start();
        }

        // 建立字段
        let segments = vec![
            // .text 段，r-x
            Segment {
                map_type: MapType::Linear,
                page_range: Range::<VirtualAddress>::from(
                    (text_start as usize)..(rodata_start as usize),
                )
                .into(),
                flags: Flags::VALID | Flags::READABLE | Flags::EXECUTABLE,
            },
            // .rodata 段，r--
            Segment {
                map_type: MapType::Linear,
                page_range: Range::<VirtualAddress>::from(
                    (rodata_start as usize)..(data_start as usize),
                )
                .into(),
                flags: Flags::VALID | Flags::READABLE,
            },
            // .data 段，rw-
            Segment {
                map_type: MapType::Linear,
                page_range: Range::<VirtualAddress>::from(
                    (data_start as usize)..(bss_start as usize),
                )
                .into(),
                flags: Flags::VALID | Flags::READABLE | Flags::WRITABLE,
            },
            // .bss 段，rw-
            Segment {
                map_type: MapType::Linear,
                page_range: Range::from(
                    VirtualAddress::from(bss_start as usize)..*KERNEL_END_ADDRESS,
                ),
                flags: Flags::VALID | Flags::READABLE | Flags::WRITABLE,
            },
            // 剩余内存空间，rw-
            Segment {
                map_type: MapType::Linear,
                page_range: Range::from(
                    *KERNEL_END_ADDRESS..VirtualAddress::from(MEMORY_END_ADDRESS),
                ),
                flags: Flags::VALID | Flags::READABLE | Flags::WRITABLE,
            },
        ];
        let mut mapping = Mapping::new()?;
        // 准备保存所有新分配的物理页面
        let mut allocated_pairs: Box<dyn Iterator<Item = (VirtualPageNumber, FrameTracker)>> =
            Box::new(core::iter::empty());

        // 每个字段在页表中进行映射
        for segment in segments.iter() {
            let new_pairs = mapping.map(segment)?;
            // 同时将新分配的映射关系保存到 allocated_pairs 中
            allocated_pairs = Box::new(allocated_pairs.chain(new_pairs.into_iter()));
        }
        Ok(MemorySet { mapping, segments })
    }

    /// 替换 `satp` 以激活页表
    ///
    /// 如果当前页表就是自身，则不会替换，但仍然会刷新 TLB。
    pub fn activate(&self) {
        self.mapping.activate()
    }
}
