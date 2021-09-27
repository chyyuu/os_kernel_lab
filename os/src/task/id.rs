use alloc::{vec::Vec, sync::Arc};
use lazy_static::*;
use crate::sync::UPSafeCell;
use crate::mm::{KERNEL_SPACE, MapPermission, VirtAddr};
use crate::config::{
    PAGE_SIZE,
    TRAMPOLINE,
    KERNEL_STACK_SIZE,
};
use super::ProcessControlBlock;

pub struct RecycleAllocator {
    current: usize,
    recycled: Vec<usize>,
}

impl RecycleAllocator {
    pub fn new() -> Self {
        RecycleAllocator {
            current: 0,
            recycled: Vec::new(),
        }
    }
    pub fn alloc(&mut self) -> usize {
        if let Some(id) = self.recycled.pop() {
            id
        } else {
            self.current += 1;
            self.current - 1
        }
    }
    pub fn dealloc(&mut self, id: usize) {
        assert!(id < self.current);
        assert!(
            self.recycled.iter().find(|i| **i == id).is_none(),
            "id {} has been deallocated!", id
        );
        self.recycled.push(id);
    }
}

lazy_static! {
    static ref PID_ALLOCATOR: UPSafeCell<RecycleAllocator> = unsafe {
        UPSafeCell::new(RecycleAllocator::new())
    };

    static ref KSTACK_ALLOCATOR: UPSafeCell<RecycleAllocator> = unsafe {
        UPSafeCell::new(RecycleAllocator::new())
    };
}

pub struct PidHandle(pub usize);

pub fn pid_alloc() -> PidHandle {
    PidHandle(PID_ALLOCATOR.exclusive_access().alloc())
}

impl Drop for PidHandle {
    fn drop(&mut self) {
        PID_ALLOCATOR.exclusive_access().dealloc(self.0);
    }
}

/// Return (bottom, top) of a kernel stack in kernel space.
pub fn kernel_stack_position(kstack_id: usize) -> (usize, usize) {
    let top = TRAMPOLINE - kstack_id * (KERNEL_STACK_SIZE + PAGE_SIZE);
    let bottom = top - KERNEL_STACK_SIZE;
    (bottom, top)
}

pub struct KernelStack(pub usize);

pub fn kstack_alloc() -> KernelStack {
    let kstack_id = KSTACK_ALLOCATOR.exclusive_access().alloc();
    let (kstack_bottom, kstack_top) = kernel_stack_position(kstack_id);
    KERNEL_SPACE
        .exclusive_access()
        .insert_framed_area(
            kstack_bottom.into(),
            kstack_top.into(),
            MapPermission::R | MapPermission::W,
        );
    KernelStack(kstack_id)
}

impl Drop for KernelStack {
    fn drop(&mut self) {
        let (kernel_stack_bottom, _) = kernel_stack_position(self.0);
        let kernel_stack_bottom_va: VirtAddr = kernel_stack_bottom.into();
        KERNEL_SPACE
            .exclusive_access()
            .remove_area_with_start_vpn(kernel_stack_bottom_va.into());
    }
}

impl KernelStack {
    #[allow(unused)]
    pub fn push_on_top<T>(&self, value: T) -> *mut T where
        T: Sized, {
        let kernel_stack_top = self.get_top();
        let ptr_mut = (kernel_stack_top - core::mem::size_of::<T>()) as *mut T;
        unsafe { *ptr_mut = value; }
        ptr_mut
    }
    pub fn get_top(&self) -> usize {
        let (_, kernel_stack_top) = kernel_stack_position(self.0);
        kernel_stack_top
    }
}

pub struct TaskUserRes {
    pub tid: usize,
    pub kstack: KernelStack,
    pub process: Arc<ProcessControlBlock>,
}

impl Drop for TaskUserRes {
    fn drop(&mut self) {
        // dealloc tid
        let process = self.process.inner_exclusive_access();
        process.task_res_allocator.dealloc(self.tid);
        // dealloc trap_cx
        process.dealloc_trap_cx(self.tid);
        // kstack can be deallocated automatically 
    }
}
