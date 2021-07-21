mod heap_allocator;
mod address;
mod frame_allocator;
mod page_table;
mod memory_set;

use page_table::PTEFlags;
use address::VPNRange;
pub use address::{PhysAddr, VirtAddr, PhysPageNum, VirtPageNum, StepByOne};
pub use frame_allocator::{FrameTracker, frame_alloc, frame_dealloc,};
pub use page_table::{
    PageTable,
    PageTableEntry,
    translated_byte_buffer,
    translated_str,
    translated_ref,
    translated_refmut,
    UserBuffer,
    UserBufferIterator,
};
pub use memory_set::{MemorySet, KERNEL_SPACE, MapPermission, kernel_token};
pub use memory_set::remap_test;

pub fn init() {
    heap_allocator::init_heap();
    frame_allocator::init_frame_allocator();
    KERNEL_SPACE.exclusive_access().activate();
}