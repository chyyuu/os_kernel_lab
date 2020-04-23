//! 保存一个线程所用到的所有内存区域（[`Segment`]）

use crate::memory::{
    address::*,
    config::*,
    mapping::{Flags, Mapping, Range, Segment},
    MemoryResult,
};
use alloc::{vec, vec::Vec};

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
            fn boot_stack_start();
        }
        // 创建 MemorySet，包含权限不同的字段
        let mut memory_set = MemorySet {
            mapping: Mapping::new()?,
            segments: vec![
                // .text 段，r-x
                Segment::Linear {
                    page_range: Range::<VirtualAddress>::from(
                        (text_start as usize)..(rodata_start as usize),
                    )
                    .into(),
                    flags: Flags::VALID | Flags::READABLE | Flags::EXECUTABLE,
                },
                // .rodata 段，r--
                Segment::Linear {
                    page_range: Range::<VirtualAddress>::from(
                        (rodata_start as usize)..(data_start as usize),
                    )
                    .into(),
                    flags: Flags::VALID | Flags::READABLE,
                },
                // .data 段，rw-
                Segment::Linear {
                    page_range: Range::<VirtualAddress>::from(
                        (data_start as usize)..(bss_start as usize),
                    )
                    .into(),
                    flags: Flags::VALID | Flags::READABLE | Flags::WRITABLE,
                },
                // .bss 段，rw-
                Segment::Linear {
                    page_range: Range::<VirtualAddress>::from(
                        (bss_start as usize)..(boot_stack_start as usize),
                    )
                    .into(),
                    flags: Flags::VALID | Flags::READABLE | Flags::WRITABLE,
                },
                // 剩余内存空间，rw-
                Segment::Linear {
                    page_range: Range::from(
                        *KERNEL_END_ADDRESS..VirtualAddress::from(MEMORY_END_ADDRESS),
                    ),
                    flags: Flags::VALID | Flags::READABLE | Flags::WRITABLE,
                },
            ],
        };
        // 所有字段在页表中进行映射
        for segment in memory_set.segments.iter() {
            memory_set.mapping.map(segment)?;
        }
        Ok(memory_set)
    }

    /// 替换 `satp` 以激活页表
    pub fn activate(&self) {
        self.mapping.activate()
    }
}
