//! 具体负责映射 / 取消映射
//!
//! 许多方法返回 [`Result`]，如果出现错误会返回 `Err(message)`。
//! NOTE：实现支持缺页（TODO），但不支持页表缺页

use crate::memory::{
    MemoryResult,
    address::*,
    frame::FRAME_ALLOCATOR,
    mapping::{Flags, PageTable, PageTableEntry, PageTableTracker, Segment},
};
use alloc::{vec, vec::Vec};
use core::ops::DerefMut;
use riscv::register::satp;

#[derive(Default)]
/// 某个线程的内存映射关系
pub struct Mapping {
    /// 保存所有使用到的页表
    ///
    /// `page_tables[0]` 是根节点
    page_tables: Vec<PageTableTracker>,
}

impl Mapping {
    /// 将当前的映射加载到 `satp` 寄存器
    pub fn activate(&self) {
        let old_satp = satp::read().bits();
        let new_satp = {
            let root_table: &PageTableTracker = self.page_tables.get(0).unwrap();
            // satp 低 27 位为页号，高 4 位为模式，8 表示 Sv39
            root_table.page_number().0 | (8 << 60)
        };
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
        let mut allocator = FRAME_ALLOCATOR.lock();
        Ok(Mapping {
            page_tables: vec![PageTableTracker::new(allocator.alloc()?)],
        })
    }

    /// 加入一段映射
    pub fn map(&mut self, segment: &Segment) -> MemoryResult<()> {
        // 遍历 segment 中所有的映射，将它们写入到页表中
        for (vpn, ppn, flags) in segment.iter() {
            self.map_one(vpn, ppn, flags)?;
        }
        Ok(())
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
        let mut new_allocated_tables = vec![];
        // 从根页表开始向下查询
        let mut page_table: &mut PageTable = self.page_tables.get_mut(0).unwrap();
        // 先查询一、二级页表
        for vpn_slice in &vpn.levels()[..2] {
            if !page_table.entries[*vpn_slice].is_empty() {
                // 进入下一级页表（使用偏移量来访问物理地址）
                page_table = page_table.entries[*vpn_slice].deref_mut();
            } else {
                // 如果页表不存在，则需要分配一个新的页表
                let new_table = PageTableTracker::new(FRAME_ALLOCATOR.lock().alloc()?);
                let new_ppn = new_table.page_number();
                // 将新页表的页号写入当前的页表
                page_table.entries[*vpn_slice] = PageTableEntry::new(new_ppn, Flags::VALID);
                // 保存页表
                new_allocated_tables.push(new_table);
                // 继续查询
                page_table = new_allocated_tables.last_mut().unwrap();
            }
        }
        // 此时 page_table 位于第三级页表
        let vpn_slice = vpn.levels()[2];
        if page_table.entries[vpn_slice].is_empty() {
            page_table.entries[vpn_slice] = PageTableEntry::new(ppn, flags);
            self.page_tables.extend(new_allocated_tables.into_iter());
            Ok(())
        } else {
            Err("virtual address is already mapped")
        }
    }

}
