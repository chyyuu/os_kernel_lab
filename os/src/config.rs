pub const PAGE_SIZE: usize = 0x1000;
pub const PAGE_SIZE_BITS: usize = 0xc;
pub const KERNEL_STACK_SIZE: usize = 4096 * 2;
pub const KERNEL_HEAP_SIZE: usize = 0x20_0000;
pub const MEMORY_END: usize = 0x80800000;
//pub const MEMORY_DMA: usize = MEMORY_END - 0x100000;
pub const MMIO: &[(usize, usize)] = &[
    (0x10001000, 0x10000),
];