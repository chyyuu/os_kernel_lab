mod context;
mod switch;
mod task;

use crate::config::MAX_APP_NUM;
use crate::loader::{get_num_app, init_app_cx};
use core::cell::RefCell;
use lazy_static::*;
use switch::__switch;
use task::{TaskControlBlock, TaskStatus};

pub use context::TaskContext;

pub struct TaskManager {
    num_app: usize,
    inner: RefCell<TaskManagerInner>,
}

struct TaskManagerInner {
    tasks: [TaskControlBlock; MAX_APP_NUM],
    current_task: usize,
}

unsafe impl Sync for TaskManager {}

lazy_static! {
    pub static ref TASK_MANAGER: TaskManager = {
        let num_app = get_num_app();
        let mut tasks = [
            TaskControlBlock { task_cx_ptr: 0, task_status: TaskStatus::UnInit };
            MAX_APP_NUM
        ];
        for i in 0..num_app {
            tasks[i].task_cx_ptr = init_app_cx(i) as * const _ as usize;
            tasks[i].task_status = TaskStatus::Ready;
        }
        TaskManager {
            num_app,
            inner: RefCell::new(TaskManagerInner {
                tasks,
                current_task: 0,
            }),
        }
    };
}

impl TaskManager {
    fn run_first_task(&self) {
        self.inner.borrow_mut().tasks[0].task_status = TaskStatus::Running;
        let next_task_cx_ptr2 = self.inner.borrow().tasks[0].get_task_cx_ptr2();
        let _unused: usize = 0;
        unsafe {
            __switch(
                &_unused as *const _,
                next_task_cx_ptr2,
            );
        }
    }

    fn mark_current_suspended(&self) {
        let mut inner = self.inner.borrow_mut();
        let current = inner.current_task;
        inner.tasks[current].task_status = TaskStatus::Ready;
    }

    fn mark_current_exited(&self) {
        let mut inner = self.inner.borrow_mut();
        let current = inner.current_task;
        inner.tasks[current].task_status = TaskStatus::Exited;
    }

    fn find_next_task(&self) -> Option<usize> {
        let inner = self.inner.borrow();
        let current = inner.current_task;
        (current + 1..current + self.num_app + 1)
            .map(|id| id % self.num_app)
            .find(|id| {
                inner.tasks[*id].task_status == TaskStatus::Ready
            })
    }

    fn run_next_task(&self) {
        if let Some(next) = self.find_next_task() {
            let mut inner = self.inner.borrow_mut();
            let current = inner.current_task;
            inner.tasks[next].task_status = TaskStatus::Running;
            inner.current_task = next;
            let current_task_cx_ptr2 = inner.tasks[current].get_task_cx_ptr2();
            let next_task_cx_ptr2 = inner.tasks[next].get_task_cx_ptr2();
            core::mem::drop(inner);
            unsafe {
                __switch(
                    current_task_cx_ptr2,
                    next_task_cx_ptr2,
                );
            }
        } else {
            panic!("All applications completed!");
        }
    }
}

pub fn run_first_task() {
    TASK_MANAGER.run_first_task();
}

fn run_next_task() {
    TASK_MANAGER.run_next_task();
}

fn mark_current_suspended() {
    TASK_MANAGER.mark_current_suspended();
}

fn mark_current_exited() {
    TASK_MANAGER.mark_current_exited();
}

pub fn suspend_current_and_run_next() {
    mark_current_suspended();
    run_next_task();
}

pub fn exit_current_and_run_next() {
    mark_current_exited();
    run_next_task();
}