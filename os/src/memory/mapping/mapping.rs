//! 具体负责映射 / 取消映射
//!
//! 许多方法返回 [`Result`]，如果出现错误会返回 `Err(message)`。
//! NOTE：实现支持缺页（TODO），但不支持页表缺页

use crate::memory::{
    address::*,
    frame::{FrameTracker, FRAME_ALLOCATOR},
    mapping::{Flags, MapType, PageTable, PageTableEntry, PageTableTracker, Segment},
    MemoryResult,
};
use alloc::{vec, vec::Vec};
use core::ops::DerefMut;
use riscv::register::satp;

#[derive(Default)]
/// 某个线程的内存映射关系
pub struct Mapping {
    /// 保存所有使用到的页表
    page_tables: Vec<PageTableTracker>,
    /// 根页表的物理页号
    root_ppn: PhysicalPageNumber,
}

impl Mapping {
    /// 将当前的映射加载到 `satp` 寄存器
    pub fn activate(&self) {
        let old_satp = satp::read().bits();
        // satp 低 27 位为页号，高 4 位为模式，8 表示 Sv39
        let new_satp = self.root_ppn.0 | (8 << 60);
        if old_satp != new_satp {
            unsafe {
                // 将 new_satp 的值写到 satp 寄存器
                llvm_asm!("csrw satp, $0" :: "r"(new_satp) :: "volatile");
                // 刷新 TLB
                llvm_asm!("sfence.vma" :::: "volatile");
            }
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
    /// 参数 `frame_limit` 为最多分配的物理页面数量。
    ///
    /// 返回所有新分配了帧的映射关系，数量不超过 `frame_limit`。
    ///
    /// 未被分配物理页面的虚拟页号暂时不会写入页表当中，它们会在发生 PageFault 后再建立页表项。
    pub fn map(
        &mut self,
        segment: &Segment,
        mut frame_limit: usize,
    ) -> MemoryResult<Vec<(VirtualPageNumber, FrameTracker)>> {
        match segment.map_type {
            // 线性映射，不需要考虑分配页面，只需将所有页面依次映射
            MapType::Linear => {
                for vpn in segment.iter() {
                    self.map_one(vpn, PhysicalPageNumber::from(vpn), segment.flags)?;
                }
                Ok(vec![])
            }
            // 按帧映射
            MapType::Framed => {
                // 记录所有成功分配的页面映射
                let mut allocated_pairs = vec![];
                // 遍历需要映射的页号
                for vpn in segment.iter() {
                    if frame_limit > 0 {
                        frame_limit -= 1;
                        // 如果还有配额，继续分配帧进行映射
                        let frame: FrameTracker = FRAME_ALLOCATOR.lock().alloc()?;
                        self.map_one(vpn, frame.page_number(), segment.flags)?;
                        allocated_pairs.push((vpn, frame));
                    } else {
                        // 没有配额则停止映射
                        break;
                    }
                }
                Ok(allocated_pairs)
            }
        }
    }

    /// 找到给定虚拟页号的三级页表项
    ///
    /// 如果找不到对应的页表项，则会相应创建页表
    pub fn find_entry(&mut self, vpn: VirtualPageNumber) -> MemoryResult<&mut PageTableEntry> {
        // 从根页表开始向下查询
        // 这里不用 self.page_tables[0] 避免后面产生 borrow-check 冲突（我太菜了）
        let root_table: &mut PageTable =
            unsafe { PhysicalAddress::from(self.root_ppn).deref_kernel() };
        let mut pte = &mut root_table.entries[vpn.levels()[0]];
        for vpn_slice in &vpn.levels()[1..] {
            if pte.is_empty() {
                // 如果页表不存在，则需要分配一个新的页表
                let new_table = PageTableTracker::new(FRAME_ALLOCATOR.lock().alloc()?);
                let new_ppn = new_table.page_number();
                // 将新页表的页号写入当前的页表项
                *pte = PageTableEntry::new(new_ppn, Flags::VALID);
                // 保存页表
                self.page_tables.push(new_table);
            }
            // 进入下一级页表（使用偏移量来访问物理地址）
            pte = &mut pte.get_next_table().entries[*vpn_slice];
        }
        // 此时 pte 位于第三级页表
        Ok(pte)
    }

    /// 为给定的虚拟 / 物理页号建立映射关系
    ///
    /// 失败后，`Mapping` 可能不再可用
    fn map_one(
        &mut self,
        vpn: VirtualPageNumber,
        ppn: PhysicalPageNumber,
        flags: Flags,
    ) -> MemoryResult<()> {
        // 定位到页表项
        let entry = self.find_entry(vpn)?;
        if entry.is_empty() {
            // 页表项为空，则写入内容
            *entry = PageTableEntry::new(ppn, flags);
            Ok(())
        } else {
            // 页表项有内容，报错
            Err("virtual address is already mapped")
        }
    }
}
