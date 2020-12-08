use super::TaskControlBlock;
use alloc::collections::VecDeque;
use alloc::sync::Arc;
use spin::Mutex;
use lazy_static::*;

pub struct TaskManager {
    ready_queue: VecDeque<Arc<Mutex<TaskControlBlock>>>,
}

/// A simple FIFO scheduler.
impl TaskManager {
    pub fn new() -> Self {
        Self { ready_queue: VecDeque::new(), }
    }
    pub fn add(&mut self, task: Arc<Mutex<TaskControlBlock>>) {
        self.ready_queue.push_back(task);
    }
    pub fn fetch(&mut self) -> Option<Arc<Mutex<TaskControlBlock>>> {
        self.ready_queue.pop_front()
    }
}

lazy_static! {
    pub static ref TASK_MANAGER: Mutex<TaskManager> = Mutex::new(TaskManager::new());
}

pub fn add_task(task: Arc<Mutex<TaskControlBlock>>) {
    TASK_MANAGER.lock().add(task);
}

pub fn fetch_task() -> Option<Arc<Mutex<TaskControlBlock>>> {
    TASK_MANAGER.lock().fetch()
}