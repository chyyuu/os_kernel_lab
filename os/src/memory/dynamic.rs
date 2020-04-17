//! 使用 `buddy_system_allocator` crate 进行动态内存分配

use super::config::KERNEL_HEAP_SIZE;
use buddy_system_allocator::LockedHeap;

/// 进行动态内存分配所用的堆空间
/// 
/// 大小为 [`KERNEL_HEAP_SIZE`]  
/// 这段空间编译后会被放在操作系统执行程序的 bss 段
static mut heap: [u8; KERNEL_HEAP_SIZE] = [0; KERNEL_HEAP_SIZE];

/// 动态内存分配器
/// 
/// ### `#[global_allocator]`
/// [`LockedHeap`] 实现了 [`alloc::alloc::GlobalAlloc`] trait，
/// 可以为全局需要用到堆的地方分配空间。例如 `Box` `Arc` 等
#[global_allocator]
static dynamic_allocator: LockedHeap = LockedHeap::empty();

/// 初始化操作系统运行时堆空间
pub fn init() {
    // 告诉分配器使用这一段预留的空间作为堆
    unsafe {
        dynamic_allocator.lock().init(
            heap.as_ptr() as usize, KERNEL_HEAP_SIZE
        )
    }
}

#[alloc_error_handler]
fn alloc_error_handler(_: alloc::alloc::Layout) -> ! {
    panic!("alloc error")
}