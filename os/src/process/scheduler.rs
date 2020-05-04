//! 线程调度器 [`Scheduler`]

use super::*;
use alloc::collections::LinkedList;

/// 线程调度器（FIFO 实现）
#[derive(Default)]
pub struct Scheduler {
    pool: LinkedList<Arc<Thread>>,
}

impl Scheduler {
    pub fn store(&mut self, thread: Arc<Thread>) {
        self.pool.push_back(thread);
    }

    pub fn get(&mut self) -> Arc<Thread> {
        self.pool.pop_front().unwrap()
    }
}