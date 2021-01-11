pub const PHYSICAL_MEMORY_END: usize = 0x80800000;

pub const KERNEL_BEGIN_PADDR: usize =  0x80020000;
pub const KERNEL_BEGIN_VADDR: usize =  0xffffffffc0020000;

pub const MAX_PHYSICAL_MEMORY: usize = 0x0800000;
pub const MAX_PHYSICAL_PAGES: usize = MAX_PHYSICAL_MEMORY >> 12;

pub const KERNEL_HEAP_SIZE: usize = 0x30_0000;

pub const PHYSICAL_MEMORY_OFFSET: usize = 0xffffffff40000000;

pub const PAGE_SIZE: usize = 4096;