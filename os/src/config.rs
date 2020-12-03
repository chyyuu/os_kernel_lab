pub const USER_STACK_SIZE: usize = 4096 * 2;
pub const KERNEL_STACK_SIZE: usize = 4096 * 2;
pub const MAX_APP_NUM: usize = 4;
pub const APP_BASE_ADDRESS: usize = 0x80100000;
pub const APP_SIZE_LIMIT: usize = 0x20000;
pub const KERNEL_HEAP_SIZE: usize = 0x30_0000;
pub const MEMORY_END: usize = 0x80800000;
pub const PAGE_SIZE: usize = 0x1000;
pub const PAGE_SIZE_BITS: usize = 0xc;

#[cfg(feature = "board_k210")]
pub const CPU_FREQ: usize = 10000000;

#[cfg(feature = "board_qemu")]
pub const CPU_FREQ: usize = 12500000;