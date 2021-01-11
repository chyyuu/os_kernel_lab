use virtio_drivers::{VirtIOBlk, VirtIOHeader};
use super::BlockDevice;
use crate::config::MEMORY_DMA;

const VIRTIO0: usize = 0x10001000;

pub struct VirtIOBlock(VirtIOBlk<'static>);


impl BlockDevice for VirtIOBlock {
    fn read_block(&mut self, block_id: usize, buf: &mut [u8]) {
        self.0.read_block(block_id, buf).expect("Error when reading VirtIOBlk");
    }
    fn write_block(&mut self, block_id: usize, buf: &[u8]) {
        self.0.write_block(block_id, buf).expect("Error when writing VirtIOBlk");
    }
}

impl VirtIOBlock {
    pub fn new() -> Self {
        Self(VirtIOBlk::new(
            unsafe { &mut *(VIRTIO0 as *mut VirtIOHeader) }
        ).expect("failed to create blk driver"))
    }
}

use core::sync::atomic::*;

static DMA_PADDR: AtomicUsize = AtomicUsize::new(MEMORY_DMA);

#[no_mangle]
extern "C" fn virtio_dma_alloc(pages: usize) -> PhysAddr {
    let paddr = DMA_PADDR.fetch_add(0x1000 * pages, Ordering::SeqCst);
    println!("alloc DMA: paddr={:#x}, pages={}", paddr, pages);
    paddr
}

#[no_mangle]
extern "C" fn virtio_dma_dealloc(paddr: PhysAddr, pages: usize) -> i32 {
    println!("dealloc DMA: paddr={:#x}, pages={}", paddr, pages);
    0
}

#[no_mangle]
extern "C" fn virtio_phys_to_virt(paddr: PhysAddr) -> VirtAddr {
    paddr
}

#[no_mangle]
extern "C" fn virtio_virt_to_phys(vaddr: VirtAddr) -> PhysAddr {
    vaddr
}

type VirtAddr = usize;
type PhysAddr = usize;