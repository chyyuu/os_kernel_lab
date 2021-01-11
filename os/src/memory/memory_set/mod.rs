pub mod attr;
pub mod handler;
pub mod area; 

use area::MemoryArea;
use attr::MemoryAttr;
use crate::memory::paging::PageTableImpl;
use crate::consts::*;
use handler::{
    MemoryHandler,
    Linear
};
use alloc::{
    boxed::Box,
    vec::Vec
};
use crate::memory::access_pa_via_va;

pub struct MemorySet {
    areas: Vec<MemoryArea>,
    page_table: PageTableImpl,
}

impl MemorySet {
    pub fn push(&mut self, start: usize, end: usize, attr: MemoryAttr, handler: impl MemoryHandler) {
        assert!(start <= end, "invalid memory area!");
        assert!(self.test_free_area(start, end), "memory area overlap!");
        let area = MemoryArea::new(start, end, Box::new(handler), attr);
        area.map(&mut self.page_table);
        self.areas.push(area);
    } 
    fn test_free_area(&self, start: usize, end: usize) -> bool {
        self.areas
            .iter()
            .find(|area| area.is_overlap_with(start, end))
            .is_none()
    }
    pub unsafe fn activate(&self) {
        self.page_table.activate();
    }
	pub fn new() -> Self {
        let mut memory_set = MemorySet {
            areas: Vec::new(),
            page_table: PageTableImpl::new_bare(),
        };
        memory_set.map_kernel_and_physical_memory();
        memory_set
    }
    pub fn map_kernel_and_physical_memory(&mut self) {
        extern "C" {
            fn stext();
            fn etext();
            fn srodata();
            fn erodata();
            fn sdata();
            fn edata();
            fn sbss();
            fn ebss();
            fn end();
        }
        let offset = PHYSICAL_MEMORY_OFFSET;
        // 各段全部采用偏移量固定的线性映射
        // .text R|X
        self.push(
            stext as usize,
            etext as usize,
            MemoryAttr::new().set_readonly().set_execute(),
            Linear::new(offset),
        );
        // .rodata R
        self.push(
            srodata as usize,
            erodata as usize,
            MemoryAttr::new().set_readonly(),
            Linear::new(offset),
        );
        // .data R|W
        self.push(
            sdata as usize,
            edata as usize,
            MemoryAttr::new(),
            Linear::new(offset)
        );
        // .bss R|W
        self.push(
            sbss as usize,
            ebss as usize,
            MemoryAttr::new(),
            Linear::new(offset)
        );
        // 物理内存 R|W
        self.push(
            (end as usize / PAGE_SIZE + 1) * PAGE_SIZE, 
            access_pa_via_va(PHYSICAL_MEMORY_END),
            MemoryAttr::new(),
            Linear::new(offset),
        );
    }
}
