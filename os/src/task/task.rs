use alloc::sync::{Arc, Weak};
use crate::{mm::PhysPageNum, sync::UPSafeCell};
use crate::trap::TrapContext;
use super::id::TaskUserRes;
use super::{
    ProcessControlBlock,
    TaskContext
};
use core::cell::RefMut;

pub struct TaskControlBlock {
    // immutable
    pub process: Weak<ProcessControlBlock>,
    // mutable
    inner: UPSafeCell<TaskControlBlockInner>,
}

impl TaskControlBlock {
    pub fn inner_exclusive_access(&self) -> RefMut<'_, TaskControlBlockInner> {
        self.inner.exclusive_access()
    }

    pub fn get_user_token(&self) -> usize {
        let process = self.process.upgrade().unwrap();
        let inner = process.inner_exclusive_access();
        inner.memory_set.token()
    }

}

pub struct TaskControlBlockInner {
    pub res: TaskUserRes,
    pub trap_cx_ppn: PhysPageNum,
    pub task_cx: TaskContext,
    pub task_status: TaskStatus,
    pub exit_code: i32,
}

impl TaskControlBlockInner {
    pub fn get_trap_cx(&self) -> &'static mut TrapContext {
        self.trap_cx_ppn.get_mut()
    }
    
    #[allow(unused)]
    fn get_status(&self) -> TaskStatus {
        self.task_status
    }
}

impl TaskControlBlock {
    pub fn new(
        process: Arc<ProcessControlBlock>,
        ustack_base: usize,
        alloc_user_res: bool
    ) -> Self {
        let res = TaskUserRes::new(Arc::clone(&process), ustack_base, alloc_user_res);
        let trap_cx_ppn = res.trap_cx_ppn();
        let kstack_top = res.kstack_top();
        Self {
            process: Arc::downgrade(&process),
            inner: unsafe { UPSafeCell::new(
                TaskControlBlockInner {
                    res,
                    trap_cx_ppn,
                    task_cx: TaskContext::goto_trap_return(kstack_top),
                    task_status: TaskStatus::Ready,
                    exit_code: 0,
                }
            )},
        }
    }
}

#[derive(Copy, Clone, PartialEq)]
pub enum TaskStatus {
    Ready,
    Running,
}
