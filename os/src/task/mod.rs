mod context;
mod switch;
mod task;
mod manager;
mod processor;
mod pid;

use crate::loader::{get_num_app, get_app_data};
use crate::trap::TrapContext;
use core::cell::RefCell;
use lazy_static::*;
use switch::__switch;
use task::{TaskControlBlock, TaskStatus};
use alloc::vec::Vec;
use alloc::sync::Arc;
use spin::Mutex;
use manager::fetch_task;
use pid::{PidHandle, pid_alloc, KernelStack};

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

pub fn suspend_current_and_run_next() {
    // There must be an application running.
    let task = current_task().unwrap();
    let task_cx_ptr = task.lock().get_task_cx_ptr2();
    // Change status to Ready.
    task.lock().task_status = TaskStatus::Ready;
    // push back to ready queue.
    add_task(task);
    // jump to scheduling cycle
    schedule(task_cx_ptr);
}

pub fn exit_current_and_run_next() {
    // The resource recycle mechanism needs child processes. Now we just panic!
    panic!("An application exited!");
}

pub fn add_application(elf_data: &[u8], app_id: usize) {
    add_task(Arc::new(Mutex::new(TaskControlBlock::new(elf_data, app_id))));
}
