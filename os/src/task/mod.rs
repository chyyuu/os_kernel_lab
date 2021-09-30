mod context;
mod switch;
mod task;
mod manager;
mod processor;
mod id;
mod process;

use crate::fs::{open_file, OpenFlags};
use switch::__switch;
use task::{TaskControlBlock, TaskStatus};
use alloc::sync::Arc;
use manager::fetch_task;
use lazy_static::*;
use process::ProcessControlBlock;

pub use context::TaskContext;
pub use processor::{
    run_tasks,
    current_task,
    current_process,
    current_user_token,
    current_trap_cx_user_va,
    current_trap_cx,
    current_kstack_top,
    take_current_task,
    schedule,
};
pub use manager::add_task;
pub use id::{
    PidHandle,
    pid_alloc,
    KernelStack,
    kstack_alloc,
};

pub fn suspend_current_and_run_next() {
    // There must be an application running.
    let task = take_current_task().unwrap();

    // ---- access current TCB exclusively
    let mut task_inner = task.inner_exclusive_access();
    let task_cx_ptr = &mut task_inner.task_cx as *mut TaskContext;
    // Change status to Ready
    task_inner.task_status = TaskStatus::Ready;
    drop(task_inner);
    // ---- release current TCB

    // push back to ready queue.
    add_task(task);
    // jump to scheduling cycle
    schedule(task_cx_ptr);
}

pub fn exit_current_and_run_next(exit_code: i32) {
    // take from Processor
    let task = take_current_task().unwrap();
    let task_exit_code = task.inner_exclusive_access().exit_code;
    let tid = task.inner_exclusive_access().res.tid;
    // remove thread 
    let process = task.process.upgrade().unwrap();
    let mut process_inner = process.inner_exclusive_access();
    process_inner.tasks.drain(tid..tid + 1);
    // if this is the main thread of the process, then we need terminate this process
    if tid == 0 {
        // mark this process as a zombie process
        process_inner.is_zombie = true;
        // record exit code of main process
        process_inner.exit_code = task_exit_code;

        {
            // move all child processes under init process
            let mut initproc_inner = INITPROC.inner_exclusive_access();
            for child in process_inner.children.iter() {
                child.inner_exclusive_access().parent = Some(Arc::downgrade(&INITPROC)); 
                initproc_inner.children.push(child.clone());
            }
        }

        process_inner.children.clear();
        // deallocate user space as soon as possible
        process_inner.memory_set.recycle_data_pages();
    }
    // maintain rc of process manually since we will break this context soon
    drop(process_inner);
    drop(process);
    drop(task);
    // we do not have to save task context
    let mut _unused = TaskContext::zero_init();
    schedule(&mut _unused as *mut _);
}

lazy_static! {
    pub static ref INITPROC: Arc<ProcessControlBlock> = {
        let inode = open_file("initproc", OpenFlags::RDONLY).unwrap();
        let v = inode.read_all();
        ProcessControlBlock::new(v.as_slice())
    };
}

pub fn add_initproc() {
    let initproc = INITPROC.clone();
}
