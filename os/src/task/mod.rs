mod context;
mod switch;
mod task;
mod manager;
mod processor;
mod pid;

use crate::loader::{get_app_data_by_name};
use switch::__switch;
use task::{TaskControlBlock, TaskStatus};
use alloc::sync::Arc;
use manager::fetch_task;
use lazy_static::*;

pub use context::TaskContext;
pub use processor::{
    run_tasks,
    current_task,
    current_user_token,
    current_trap_cx,
    take_current_task,
    schedule,
};
pub use manager::add_task;
pub use pid::{PidHandle, pid_alloc, KernelStack};

pub fn suspend_current_and_run_next() {
    // There must be an application running.
    let task = take_current_task().unwrap();

    // ---- temporarily hold current PCB lock
    let task_cx_ptr2 = task.acquire_inner_lock().get_task_cx_ptr2();
    // ---- release current PCB lock

    // ++++ temporarily hold current PCB lock
    // Change status to Ready
    task.acquire_inner_lock().task_status = TaskStatus::Ready;
    // ++++ release current PCB lock

    // push back to ready queue.
    add_task(task);
    // jump to scheduling cycle
    schedule(task_cx_ptr2);
}

pub fn exit_current_and_run_next(exit_code: i32) {
    // take from Processor
    let task = take_current_task().unwrap();
    // **** hold current PCB lock
    let mut inner = task.acquire_inner_lock();
    // Change status to Zombie
    inner.task_status = TaskStatus::Zombie;
    // Record exit code
    inner.exit_code = exit_code;
    // do not move to its parent but under initproc

    // ++++++ hold initproc PCB lock here
    {
        let mut initproc_inner = INITPROC.acquire_inner_lock();
        for child in inner.children.iter() {
            initproc_inner.children.push(child.clone());
        }
    }
    // ++++++ release parent PCB lock here

    inner.children.clear();
    // deallocate user space
    inner.memory_set.recycle_data_pages();
    drop(inner);
    // **** release current PCB lock
    // drop task manually to maintain rc correctly
    drop(task);
    // we do not have to save task context
    let _unused: usize = 0;
    schedule(&_unused as *const _);
}

lazy_static! {
    pub static ref INITPROC: Arc<TaskControlBlock> = Arc::new(
        TaskControlBlock::new(get_app_data_by_name("initproc").unwrap())
    );
}

pub fn add_initproc() {
    add_task(INITPROC.clone());
}
