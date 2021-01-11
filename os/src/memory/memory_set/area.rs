use alloc::boxed::Box;
use crate::memory::paging::{PageTableImpl, PageRange,};
use super::{attr::MemoryAttr, handler::MemoryHandler, };
use crate::consts::PAGE_SIZE;

#[derive(Debug,Clone)]
pub struct MemoryArea {
    start : usize,
    end : usize, 
    handler : Box<dyn MemoryHandler>,
    attr : MemoryAttr,
}

impl MemoryArea {
    pub fn map(&self, pt : &mut PageTableImpl) {
        for page in PageRange::new(self.start, self.end) {
            self.handler.map(pt, page, &self.attr);
        }
    }
    fn unmap(&self, pt : &mut PageTableImpl) {
        for page in PageRange::new(self.start, self.end) {
            self.handler.unmap(pt, page);
        }
    }

    pub fn is_overlap_with(&self, start_addr : usize, end_addr : usize) -> bool {
        let p1 = self.start / PAGE_SIZE;
        let p2 = (self.end - 1) / PAGE_SIZE + 1;
        let p3 = start_addr / PAGE_SIZE;
        let p4 = (end_addr - 1) / PAGE_SIZE + 1;
        !((p1 >= p4) || (p2 <= p3))
    }
	
    pub fn new(start_addr : usize, end_addr : usize, handler : Box<dyn MemoryHandler>, attr : MemoryAttr) -> Self {
        MemoryArea{
            start : start_addr,
            end : end_addr,
            handler : handler,
            attr : attr,
        }
    }
}
