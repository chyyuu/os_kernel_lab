use alloc::sync::Arc;
use crate::{mm::PhysPageNum, sync::UPSafeCell};
use crate::trap::TrapContext;
use super::{
    KernelStack,
    ProcessControlBlock,
    TaskContext
};

pub struct TaskControlBlock {
    // immutable
    pub tid: usize,
    pub kstack: KernelStack,
    pub process: Arc<ProcessControlBlock>,
    // mutable
    inner: UPSafeCell<TaskControlBlockInner>,
}

pub struct TaskControlBlockInner {
    pub trap_cx_ppn: PhysPageNum,
    pub task_cx: TaskContext,
    pub task_status: TaskStatus,
    pub exit_code: i32,
}

impl TaskControlBlockInner {
    pub fn get_trap_cx(&self) -> &'static mut TrapContext {
        self.trap_cx_ppn.get_mut()
    }
    fn get_status(&self) -> TaskStatus {
        self.task_status
    }
}

#[derive(Copy, Clone, PartialEq)]
pub enum TaskStatus {
    Ready,
    Running,
}
