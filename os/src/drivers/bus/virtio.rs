use super::super::block::virtio_blk;
use crate::memory::{frame::{FrameTracker, FRAME_ALLOCATOR}, PhysicalAddress, VirtualAddress, PAGE_SIZE};
use alloc::collections::btree_map::BTreeMap;
use device_tree::util::SliceRead;
use device_tree::Node;
use lazy_static::lazy_static;
use virtio_drivers::{DeviceType, VirtIOHeader};
use spin::RwLock;

pub fn virtio_probe(node: &Node) {
    let reg = match node.prop_raw("reg") {
        Some(reg) => reg,
        _ => return,
    };
    let paddr = PhysicalAddress(reg.as_slice().read_be_u64(0).unwrap() as usize);
    let vaddr = VirtualAddress::from(paddr);
    let size = reg.as_slice().read_be_u64(8).unwrap();
    // assuming one page
    assert_eq!(size as usize, 4096);
    let header = unsafe { &mut *(vaddr.0 as *mut VirtIOHeader) };
    if !header.verify() {
        // only support legacy device
        return;
    }
    println!("vendor id: {:#x}", header.vendor_id());
    println!("Device tree node {:?}", node);
    match header.device_type() {
        DeviceType::Block => virtio_blk::add_driver(header),
        device => println!("unrecognized virtio device: {:?}", device),
    }
}

lazy_static! {
    pub static ref TRACKERS: RwLock<BTreeMap<PhysicalAddress, FrameTracker>> = RwLock::new(BTreeMap::new());
}

#[no_mangle]
extern "C" fn virtio_dma_alloc(pages: usize) -> PhysicalAddress {
    let mut paddr: PhysicalAddress = Default::default();
    let mut last: PhysicalAddress = Default::default();
    for i in 0..pages {
        let tracker: FrameTracker = FRAME_ALLOCATOR.lock().alloc().unwrap();
        if i == 0 {
            paddr = tracker.address();
        } else {
            assert_eq!(last + PAGE_SIZE, tracker.address());
        }
        last = tracker.address();
        TRACKERS.write().insert(last, tracker);
    }
    return paddr;
}

#[no_mangle]
extern "C" fn virtio_dma_dealloc(paddr: PhysicalAddress, pages: usize) -> i32 {
    for i in 0..pages {
        TRACKERS.write().remove(&(paddr + i * PAGE_SIZE));
    }
    0
}

#[no_mangle]
extern "C" fn virtio_phys_to_virt(paddr: PhysicalAddress) -> VirtualAddress {
    VirtualAddress::from(paddr)
}

#[no_mangle]
extern "C" fn virtio_virt_to_phys(vaddr: VirtualAddress) -> PhysicalAddress {
    PhysicalAddress::from(vaddr)
}
