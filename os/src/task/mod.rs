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
    let task_cx_ptr = task.acquire_inner_lock().get_task_cx_ptr2();
    // ---- release current PCB lock

    // ++++ temporarily hold current PCB lock
    // Change status to Ready
    task.acquire_inner_lock().task_status = TaskStatus::Ready;
    // ++++ release current PCB lock

    // push back to ready queue.
    add_task(task);
    // jump to scheduling cycle
    schedule(task_cx_ptr);
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
    // move any child to its parent
    // TODO: do not move to its parent but under initproc

    // ++++++ hold parent PCB lock here
    {
        let parent = inner.parent.as_ref().unwrap().upgrade().unwrap();
        let mut parent_inner = parent.acquire_inner_lock();
        for child in inner.children.iter() {
            parent_inner.children.push(child.clone());
        }
    }
    // ++++++ release parent PCB lock here

    inner.children.clear();
    // deallocate user space
    inner.memory_set.clear();
    drop(inner);
    // **** release current PCB lock
    // drop task manually to maintain rc correctly
    drop(task);
    // we do not have to save task context
    let _unused: usize = 0;
    schedule(&_unused as *const _);
}

pub fn add_initproc() {
    let data = get_app_data_by_name("initproc").unwrap();
    add_task(Arc::new(TaskControlBlock::new(data)));
}
