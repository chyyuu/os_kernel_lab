//! 一个线程中关于内存空间的所有信息 [`MemorySet`]
//!
//! # 内存置换
//! *（这里只是提供了一种实现，不代表主流操作系统是这样做的）*  
//! 由操作系统设置一个 `frame_limit`，指定线程能够使用多少物理页面，而页表所使用的的页面不算在内。

use crate::memory::{
    address::*,
    config::*,
    frame::FrameTracker,
    mapping::{Flags, MapType, Mapping, Range, Segment, Swapper},
    MemoryResult,
};
use crate::file_system::SWAP_FILE;
use crate::process::current_tid;
use alloc::{boxed::Box, vec, vec::Vec};

/// 一个线程所有关于内存空间管理的信息
pub struct MemorySet {
    /// 限制此线程能够使用的物理页面数量（不包括页表使用的）
    pub frame_limit: usize,
    /// 维护页表和映射关系
    pub mapping: Mapping,
    /// 管理页面置换
    pub swapper: Swapper,
    /// 每个字段
    pub segments: Vec<Segment>,
}

impl MemorySet {
    /// 简单测试代码，为虚拟地址分配一个页
    pub fn test_map_alloc(&mut self, vpn: VirtualPageNumber) -> MemoryResult<()> {
        let segment = Segment {
            map_type: MapType::Framed,
            page_range: Range::from(vpn..vpn + 1),
            flags: Flags::VALID | Flags::READABLE | Flags::WRITABLE,
        };
        let frame_limit = self.frame_limit - self.swapper.len();
        if let Some(pair) = self.mapping.map(&segment, frame_limit)?.pop() {
            self.swapper.add_pair(pair);
        }
        self.segments.push(segment);
        Ok(())
    }

    /// 创建内核重映射
    pub fn new_kernel(frame_limit: usize) -> MemoryResult<MemorySet> {
        // 在 linker.ld 里面标记的各个字段的起始点，均为 4K 对齐
        extern "C" {
            fn text_start();
            fn rodata_start();
            fn data_start();
            fn bss_start();
            fn boot_stack_start();
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
            // 模拟硬盘空间，rw-
            Segment {
                map_type: MapType::Linear,
                page_range: Range::<VirtualAddress>::from(
                    HDD_START_ADDRESS..HDD_END_ADDRESS,
                ).into(),
                flags: Flags::VALID | Flags::READABLE | Flags::WRITABLE,
            },
        ];
        let mut mapping = Mapping::new()?;
        let mut frame_limit_remainder = frame_limit;
        // 准备保存所有新分配的物理页面
        let mut allocated_pairs: Box<dyn Iterator<Item = (VirtualPageNumber, FrameTracker)>> =
            Box::new(core::iter::empty());

        // 每个字段在页表中进行映射
        for segment in segments.iter() {
            let new_pairs = mapping.map(segment, frame_limit_remainder)?;
            // 如果字段的映射涉及到分配更多物理页面，则需要相应消耗 frame_limit，
            // 同时将新分配的映射关系保存到 allocated_pairs 中
            frame_limit_remainder -= new_pairs.len();
            allocated_pairs = Box::new(allocated_pairs.chain(new_pairs.into_iter()));
        }
        // 映射完毕，初始化页面置换模块
        let swapper = Swapper::new(frame_limit, allocated_pairs);
        Ok(MemorySet {
            frame_limit,
            mapping,
            swapper,
            segments,
        })
    }

    /// 替换 `satp` 以激活页表
    ///
    /// 如果当前页表就是自身，则不会替换，但仍然会刷新 TLB。
    pub fn activate(&self) {
        self.mapping.activate()
    }

    /// 缺页时，换走一个页面，加入需要的页面
    pub fn resolve_page_fault(&mut self, stval: usize) -> MemoryResult<()> {
        let vpn = VirtualPageNumber::floor(VirtualAddress::from(stval));
        // 确认目标页面为 Invalid，否则可能是权限导致的异常，操作系统不会解决这种异常
        if self.mapping.find_entry(vpn)?.flags().contains(Flags::VALID) {
            return Err("page fault: illegal access");
        }
        // 找到页面所属 segment 的 flags
        let flags = self
            .segments
            .iter()
            .find(|segment| segment.contains(vpn))
            .ok_or("cannot find segment for page fault stval (perhaps illegal access)")?
            .flags;
        // 选择被替换的页面
        let (victim_vpn, frame) = self
            .swapper
            .choose_victim()
            .ok_or("page fault while Swapper is not full")?;
        // 保存页面到硬盘
        let thread_id = current_tid();
        SWAP_FILE.lock().save(thread_id, victim_vpn, frame.page_number().deref_kernel())?;
        // 如果换入的页面之前存有数据，则取出
        if let Some(saved_data) = SWAP_FILE.lock().take(thread_id, vpn) {
            frame.page_number().deref_kernel().copy_from_slice(saved_data);
        }
        // 替换映射
        self.mapping.swap_out(victim_vpn)?;
        self.mapping.swap_in(vpn, frame.page_number(), flags)?;
        self.swapper.add_pair((vpn, frame));
        // 更新 TLB
        self.activate();
        Ok(())
    }
}
