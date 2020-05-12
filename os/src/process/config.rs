//! 定义一些进程相关的常量

/// 每个线程的运行栈大小 512 KB
pub const STACK_SIZE: usize = 0x8_0000;

/// 共用的内核栈大小 512 KB
pub const KERNEL_STACK_SIZE: usize = 0x8_0000;
