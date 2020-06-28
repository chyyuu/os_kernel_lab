//! virtio MMIO 总线协议驱动
//!
//! 目前仅仅实现了 virtio Block Device 协议，另外还有类似 virtio Network 等协议

use super::super::block::virtio_blk;
use crate::memory::{
    frame::{FrameTracker, FRAME_ALLOCATOR},
    mapping::Mapping,
    PhysicalAddress, VirtualAddress, PAGE_SIZE,
};
use alloc::collections::btree_map::BTreeMap;
use device_tree::{util::SliceRead, Node};
use lazy_static::lazy_static;
use spin::RwLock;
use virtio_drivers::{DeviceType, VirtIOHeader};

/// 从设备树的某个节点探测 virtio 协议具体类型
pub fn virtio_probe(node: &Node) {
    // reg 属性中包含了描述设备的 Header 的位置
    let reg = match node.prop_raw("reg") {
        Some(reg) => reg,
        _ => return,
    };
    let pa = PhysicalAddress(reg.as_slice().read_be_u64(0).unwrap() as usize);
    let va = VirtualAddress::from(pa);
    let header = unsafe { &mut *(va.0 as *mut VirtIOHeader) };
    // 目前只支持某个特定版本的 virtio 协议
    if !header.verify() {
        return;
    }
    // 判断设备类型
    match header.device_type() {
        DeviceType::Block => virtio_blk::add_driver(header),
        device => println!("unrecognized virtio device: {:?}", device),
    }
}

lazy_static! {
    /// 用于放置给设备 DMA 所用的物理页（[`FrameTracker`]）
    pub static ref TRACKERS: RwLock<BTreeMap<PhysicalAddress, FrameTracker>> =
        RwLock::new(BTreeMap::new());
}

/// 为 DMA 操作申请连续 pages 个物理页（为 [`virtio_drivers`] 库提供）
///
/// 为什么要求连续的物理内存？设备的 DMA 操作只涉及到内存和对应设备
/// 这个过程不会涉及到 CPU 的 MMU 机制，我们只能给设备传递物理地址
/// 而陷于我们之前每次只能分配一个物理页的设计，这里我们假设我们连续分配的地址是连续的
#[no_mangle]
extern "C" fn virtio_dma_alloc(pages: usize) -> PhysicalAddress {
    let mut pa: PhysicalAddress = Default::default();
    let mut last: PhysicalAddress = Default::default();
    for i in 0..pages {
        let tracker: FrameTracker = FRAME_ALLOCATOR.lock().alloc().unwrap();
        if i == 0 {
            pa = tracker.address();
        } else {
            assert_eq!(last + PAGE_SIZE, tracker.address());
        }
        last = tracker.address();
        TRACKERS.write().insert(last, tracker);
    }
    pa
}

/// 为 DMA 操作释放对应的之前申请的连续的物理页（为 [`virtio_drivers`] 库提供）
#[no_mangle]
extern "C" fn virtio_dma_dealloc(pa: PhysicalAddress, pages: usize) -> i32 {
    for i in 0..pages {
        TRACKERS.write().remove(&(pa + i * PAGE_SIZE));
    }
    0
}

/// 将物理地址转为虚拟地址（为 [`virtio_drivers`] 库提供）
///
/// 需要注意，我们在 0xffffffff80200000 到 0xffffffff88000000 是都有对应的物理地址映射的
/// 因为在内核重映射的时候，我们已经把全部的段放进去了
/// 所以物理地址直接加上 Offset 得到的虚拟地址是可以通过任何内核进程的页表来访问的
#[no_mangle]
extern "C" fn virtio_phys_to_virt(pa: PhysicalAddress) -> VirtualAddress {
    VirtualAddress::from(pa)
}

/// 将虚拟地址转为物理地址（为 [`virtio_drivers`] 库提供）
///
/// 需要注意，实现这个函数的目的是告诉 DMA 具体的请求，请求在实现中会放在栈上面
/// 而在我们的实现中，栈是以 Framed 的形式分配的，并不是高地址的线性映射 Linear
/// 为了得到正确的物理地址并告诉 DMA 设备，我们只能查页表
#[no_mangle]
extern "C" fn virtio_virt_to_phys(va: VirtualAddress) -> PhysicalAddress {
    Mapping::lookup(va).unwrap()
}
