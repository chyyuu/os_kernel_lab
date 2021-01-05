pub const PHYSICAL_MEMORY_END: usize = 0x80800000;

pub const KERNEL_BEGIN_PADDR: usize = 0x80200000;
pub const KERNEL_BEGIN_VADDR: usize = 0x80020000;

pub const MAX_PHYSICAL_MEMORY: usize = 0x0800000;
pub const MAX_PHYSICAL_PAGES: usize = MAX_PHYSICAL_MEMORY >> 12;

pub const KERNEL_HEAP_SIZE: usize = 0x30_0000;

