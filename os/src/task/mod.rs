mod context;
mod switch;

use crate::config::MAX_APP_NUM;
use crate::loader::{get_num_app, init_app_cx};
use core::cell::RefCell;
use lazy_static::*;
use switch::__switch;

pub use context::TaskContext;

struct TaskControlBlock {
    task_cx_ptr: usize,
}

pub struct TaskManager {
    num_app: usize,
    tasks: [TaskControlBlock; MAX_APP_NUM],
    current_task: RefCell<usize>,
}

unsafe impl Sync for TaskManager {}

lazy_static! {
    pub static ref TASK_MANAGER: TaskManager = {
        let num_app = get_num_app();
        let mut tasks = [TaskControlBlock { task_cx_ptr: 0 }; MAX_APP_NUM];
        for i in 0..num_app {
            tasks[i] = TaskControlBlock { task_cx_ptr: init_app_cx(i) as *const _ as usize, };
        }
        TaskManager {
            num_app,
            tasks,
            current_task: RefCell::new(0),
        }
    };
}

impl TaskManager {
    pub fn run_first_task(&self) {
        unsafe {
            __switch(&0usize, &self.tasks[0].task_cx_ptr);
        }
    }
    pub fn switch_to_next_task(&self) {
        let current = *self.current_task.borrow();
        let next = if current == self.num_app - 1 { 0 } else { current + 1 };
        *self.current_task.borrow_mut() = next;
        unsafe {
            __switch(&self.tasks[current].task_cx_ptr, &self.tasks[next].task_cx_ptr);
        }
    }
}

pub fn run_first_task() {
    TASK_MANAGER.run_first_task();
}

pub fn switch_to_next_task() {
    TASK_MANAGER.switch_to_next_task();
}