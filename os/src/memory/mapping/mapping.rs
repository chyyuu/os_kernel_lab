//! Rv39 页表的构建 [`Mapping`]
//!
//! 许多方法返回 [`Result`]，如果出现错误会返回 `Err(message)`。设计目标是，此时如果终止线程，则不会产生后续问题。
//! 但是如果错误是由操作系统代码逻辑产生的，则会直接 panic。

use crate::memory::{
    address::*,
    config::PAGE_SIZE,
    frame::{FrameTracker, FRAME_ALLOCATOR},
    mapping::{Flags, MapType, PageTable, PageTableEntry, PageTableTracker, Segment},
    MemoryResult,
};
use alloc::{vec, vec::Vec};
use core::cmp::min;
use core::ptr::slice_from_raw_parts_mut;

#[derive(Default)]
/// 某个进程的内存映射关系
pub struct Mapping {
    /// 保存所有使用到的页表
    page_tables: Vec<PageTableTracker>,
    /// 根页表的物理页号
    root_ppn: PhysicalPageNumber,
}

impl Mapping {
    /// 将当前的映射加载到 `satp` 寄存器并记录
    pub fn activate(&self) {
        // satp 低 27 位为页号，高 4 位为模式，8 表示 Sv39
        let new_satp = self.root_ppn.0 | (8 << 60);
        unsafe {
            // 将 new_satp 的值写到 satp 寄存器
            llvm_asm!("csrw satp, $0" :: "r"(new_satp) :: "volatile");
            // 刷新 TLB
            llvm_asm!("sfence.vma" :::: "volatile");
        }
    }

    /// 创建一个有根节点的映射
    pub fn new() -> MemoryResult<Mapping> {
        let root_table = PageTableTracker::new(FRAME_ALLOCATOR.lock().alloc()?);
        let root_ppn = root_table.page_number();
        Ok(Mapping {
            page_tables: vec![root_table],
            root_ppn,
        })
    }

    /// 加入一段映射，可能会相应地分配物理页面
    ///
    /// 未被分配物理页面的虚拟页号暂时不会写入页表当中，它们会在发生 PageFault 后再建立页表项。
    pub fn map(
        &mut self,
        segment: &Segment,
        init_data: Option<&[u8]>,
    ) -> MemoryResult<Vec<(VirtualPageNumber, FrameTracker)>> {
        match segment.map_type {
            MapType::Linear => {
                // 线性映射，直接对虚拟地址进行转换
                for vpn in segment.page_range().iter() {
                    self.map_one(vpn, vpn.into(), segment.flags | Flags::VALID)?;
                }
                // 拷贝数据
                if let Some(data) = init_data {
                    unsafe {
                        (&mut *slice_from_raw_parts_mut(segment.range.start.deref(), data.len()))
                            .copy_from_slice(data);
                    }
                }
                Ok(Vec::new())
            }
            MapType::Framed => {
                // 需要再分配帧进行映射

                // 记录所有成功分配的页面映射
                let mut allocated_pairs = Vec::new();
                for vpn in segment.page_range().iter() {
                    let frame = FRAME_ALLOCATOR.lock().alloc()?;
                    let frame_address = frame.address();

                    self.map_one(vpn, frame.page_number(), segment.flags | Flags::VALID)?;
                    allocated_pairs.push((vpn, frame));

                    // 拷贝数据，注意页表尚未应用，无法直接从刚刚映射的虚拟地址访问，因此必须用物理地址 + 偏移来访问。
                    if let Some(data) = init_data {
                        unsafe {
                            if data.is_empty() {
                                // bss 段中，data 长度为 0，但是仍需要 0-初始化整个空间
                                (&mut *slice_from_raw_parts_mut(
                                    frame_address.deref_kernel(),
                                    PAGE_SIZE,
                                ))
                                    .fill(0);
                            } else {
                                // 拷贝时考虑区间与整页不对齐的特殊情况
                                // 这里默认每个字段的起始位置一定是 4K 对齐的
                                let copy_size =
                                    min(PAGE_SIZE, segment.range.end - VirtualAddress::from(vpn));
                                (&mut *slice_from_raw_parts_mut(
                                    frame_address.deref_kernel(),
                                    copy_size,
                                ))
                                    .copy_from_slice(
                                        &data[VirtualAddress::from(vpn) - segment.range.start
                                            ..VirtualAddress::from(vpn) - segment.range.start
                                                + copy_size],
                                    );
                            }
                        }
                    }
                }
                Ok(allocated_pairs)
            }
        }
    }

    /// 移除一段映射
    pub fn unmap(&mut self, segment: &Segment) {
        for vpn in segment.page_range().iter() {
            let entry = self.find_entry(vpn).unwrap();
            assert!(!entry.is_empty());
            // 从页表中清除项
            entry.clear();
        }
    }

    /// 找到给定虚拟页号的三级页表项
    ///
    /// 如果找不到对应的页表项，则会相应创建页表
    pub fn find_entry(&mut self, vpn: VirtualPageNumber) -> MemoryResult<&mut PageTableEntry> {
        // 从根页表开始向下查询
        // 这里不用 self.page_tables[0] 避免后面产生 borrow-check 冲突（我太菜了）
        let root_table: &mut PageTable = PhysicalAddress::from(self.root_ppn).deref_kernel();
        let mut entry = &mut root_table.entries[vpn.levels()[0]];
        for vpn_slice in &vpn.levels()[1..] {
            if entry.is_empty() {
                // 如果页表不存在，则需要分配一个新的页表
                let new_table = PageTableTracker::new(FRAME_ALLOCATOR.lock().alloc()?);
                let new_ppn = new_table.page_number();
                // 将新页表的页号写入当前的页表项
                *entry = PageTableEntry::new(new_ppn, Flags::VALID);
                // 保存页表
                self.page_tables.push(new_table);
            }
            // 进入下一级页表（使用偏移量来访问物理地址）
            entry = &mut entry.get_next_table().entries[*vpn_slice];
        }
        // 此时 entry 位于第三级页表
        Ok(entry)
    }

    /// 查找虚拟地址对应的物理地址
    pub fn lookup(va: VirtualAddress) -> Option<PhysicalAddress> {
        let mut current_ppn;
        unsafe {
            llvm_asm!("csrr $0, satp" : "=r"(current_ppn) ::: "volatile");
            current_ppn ^= 8 << 60;
        }

        let root_table: &PageTable =
            PhysicalAddress::from(PhysicalPageNumber(current_ppn)).deref_kernel();
        let vpn = VirtualPageNumber::floor(va);
        let mut entry = &root_table.entries[vpn.levels()[0]];
        // 为了支持大页的查找，我们用 length 表示查找到的物理页需要加多少位的偏移
        let mut length = 12 + 2 * 9;
        for vpn_slice in &vpn.levels()[1..] {
            if entry.is_empty() {
                return None;
            }
            if entry.has_next_level() {
                length -= 9;
                entry = &mut entry.get_next_table().entries[*vpn_slice];
            } else {
                break;
            }
        }
        let base = PhysicalAddress::from(entry.page_number()).0;
        let offset = va.0 & ((1 << length) - 1);
        Some(PhysicalAddress(base + offset))
    }

    /// 为给定的虚拟 / 物理页号建立映射关系
    fn map_one(
        &mut self,
        vpn: VirtualPageNumber,
        ppn: PhysicalPageNumber,
        flags: Flags,
    ) -> MemoryResult<()> {
        // 定位到页表项
        let entry = self.find_entry(vpn)?;
        assert!(entry.is_empty(), "virtual address is already mapped");
        // 页表项为空，则写入内容
        *entry = PageTableEntry::new(ppn, flags);
        Ok(())
    }
}
