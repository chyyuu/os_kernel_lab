use super::TaskControlBlock;
use alloc::sync::Arc;
use spin::Mutex;
use lazy_static::*;
use super::{add_task, fetch_task};
use super::__switch;
use crate::trap::TrapContext;

pub struct Processor {
    inner: Mutex<ProcessorInner>,
}

unsafe impl Sync for Processor {}

struct ProcessorInner {
    current: Option<Arc<Mutex<TaskControlBlock>>>,
    idle_task_cx_ptr: usize,
}

impl Processor {
    pub fn new() -> Self {
        Self {
            inner: Mutex::new(ProcessorInner {
                current: None,
                idle_task_cx_ptr: 0,
            }),
        }
    }
    fn get_idle_task_cx_ptr2(&self) -> *const usize {
        let inner = self.inner.lock();
        &inner.idle_task_cx_ptr as *const usize
    }
    pub fn run(&self) {
        //println!("into Processor::run");
        loop {
            if let Some(task) = fetch_task() {
                //println!("found task!");
                let idle_task_cx_ptr = self.get_idle_task_cx_ptr2();
                let next_task_cx_ptr = task.lock().get_task_cx_ptr2();
                //println!("next_task_cx_ptr={:p}", next_task_cx_ptr);
                self.inner.lock().current = Some(task);
                unsafe {
                    __switch(
                        idle_task_cx_ptr,
                        next_task_cx_ptr,
                    );
                }
            }
        }
    }
    pub fn take_current(&self) -> Option<Arc<Mutex<TaskControlBlock>>> {
        self.inner.lock().current.take()
    }
    pub fn current(&self) -> Option<Arc<Mutex<TaskControlBlock>>> {
        self.inner.lock().current.as_ref().map(|task| task.clone())
    }
}

lazy_static! {
    pub static ref PROCESSOR: Processor = Processor::new();
}

pub fn run_tasks() {
    PROCESSOR.run();
}

pub fn take_current_task() -> Option<Arc<Mutex<TaskControlBlock>>> {
    PROCESSOR.take_current()
}

pub fn current_task() -> Option<Arc<Mutex<TaskControlBlock>>> {
    //println!("into current_task!");
    PROCESSOR.current()
}

pub fn current_user_token() -> usize {
    //println!("into current_user_token!");
    let task = current_task().unwrap();
    //println!("Got task in current_user_token!");
    let token = task.lock().get_user_token();
    token
}

pub fn current_trap_cx() -> &'static mut TrapContext {
    current_task().unwrap().as_ref().lock().get_trap_cx()
}

pub fn schedule(switched_task_cx_ptr2: *const usize) {
    let idle_task_cx_ptr2 = PROCESSOR.get_idle_task_cx_ptr2();
    unsafe {
        __switch(
            switched_task_cx_ptr2,
            idle_task_cx_ptr2,
        );
    }
}
