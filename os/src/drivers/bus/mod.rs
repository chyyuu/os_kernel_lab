//! 总线协议驱动
//!
//! 目前仅仅实现了 virtio MMIO 协议，另外还有类似 PCI 等协议
//! MMIO 指通过读写特定内存段来实现设备交互

pub mod virtio_mmio;
