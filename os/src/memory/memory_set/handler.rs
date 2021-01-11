use crate::memory::paging::PageTableImpl;
use super::attr::MemoryAttr;
use crate::memory::alloc_frame; 
use core::fmt::Debug;
use alloc::boxed::Box;


pub trait MemoryHandler: Debug + 'static {
    fn box_clone(&self) -> Box<dyn MemoryHandler>;
    fn map(&self, pt: &mut PageTableImpl, va: usize, attr: &MemoryAttr);
    fn unmap(&self, pt: &mut PageTableImpl, va: usize);
}

impl Clone for Box<dyn MemoryHandler> {
    fn clone(&self) -> Box<dyn MemoryHandler> { self.box_clone() }
}


#[derive(Debug, Clone)]
pub struct Linear { offset: usize }

impl Linear {
    pub fn new(off: usize) -> Self {
        Linear { offset: off, }
    }
}
impl MemoryHandler for Linear {
    fn box_clone(&self) -> Box<dyn MemoryHandler> { Box::new(self.clone()) }
    fn map(&self, pt: &mut PageTableImpl, va: usize, attr: &MemoryAttr) {
        attr.apply(pt.map(va, va - self.offset));
    }
    fn unmap(&self, pt: &mut PageTableImpl, va: usize) {
        pt.unmap(va);
    }
}

#[derive(Debug, Clone)]
pub struct ByFrame;
impl ByFrame {
    pub fn new() -> Self {
        ByFrame {}
    }
}
impl MemoryHandler for ByFrame {
    fn box_clone(&self) -> Box<dyn MemoryHandler> {
        Box::new(self.clone())
    }

    fn map(&self, pt: &mut PageTableImpl, va: usize, attr: &MemoryAttr) {
        let frame = alloc_frame().expect("alloc_frame failed!");
        let pa = frame.start_address().as_usize();
        attr.apply(pt.map(va, pa));
    }

    fn unmap(&self, pt: &mut PageTableImpl, va: usize) {
        pt.unmap(va);
    }
}
