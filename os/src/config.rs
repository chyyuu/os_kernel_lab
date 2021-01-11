pub const MEMORY_END: usize = 0x80800000;
pub const MEMORY_DMA: usize = MEMORY_END - 0x100000;
pub const MMIO: &[(usize, usize)] = &[
    (0x10001000, 0x10000),
];