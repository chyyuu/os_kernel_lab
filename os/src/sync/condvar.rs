use crate::sync::{Mutex, UPIntrFreeCell};
use crate::task::{
    add_task, block_current_and_run_next, block_current_task, current_task, TaskContext,
    TaskControlBlock,
};
use alloc::{collections::VecDeque, sync::Arc};

pub struct Condvar {
    pub inner: UPIntrFreeCell<CondvarInner>,
}

pub struct CondvarInner {
    pub wait_queue: VecDeque<Arc<TaskControlBlock>>,
}

impl Condvar {
    pub fn new() -> Self {
        Self {
            inner: unsafe {
                UPIntrFreeCell::new(CondvarInner {
                    wait_queue: VecDeque::new(),
                })
            },
        }
    }

    pub fn signal(&self) {
        let mut inner = self.inner.exclusive_access();
        if let Some(task) = inner.wait_queue.pop_front() {
            add_task(task);
        }
    }

    /*
    pub fn wait(&self) {
        let mut inner = self.inner.exclusive_access();
        inner.wait_queue.push_back(current_task().unwrap());
        drop(inner);
        block_current_and_run_next();
    }
    */

    pub fn wait_no_sched(&self) -> *mut TaskContext {
        self.inner.exclusive_session(|inner| {
            inner.wait_queue.push_back(current_task().unwrap());
        });
        block_current_task()
    }

    pub fn wait_with_mutex(&self, mutex: Arc<dyn Mutex>) {
        mutex.unlock();
        self.inner.exclusive_session(|inner| {
            inner.wait_queue.push_back(current_task().unwrap());
        });
        block_current_and_run_next();
        mutex.lock();
    }
}
