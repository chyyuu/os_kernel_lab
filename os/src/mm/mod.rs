pub mod heap_allocator;
mod address;
pub mod frame_allocator;

pub use address::{PhysAddr, VirtAddr, PhysPageNum, VirtPageNum};
pub use frame_allocator::{FrameTracker, frame_alloc};

pub fn init() {
    heap_allocator::init_heap();
    frame_allocator::init_frame_allocator();
}