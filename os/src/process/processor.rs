//! 处理器，进程管理的最高结构

use super::*;
use alloc::sync::Arc;
use spin::*;

pub static mut PROCESSOR: Processor = Processor::new();

pub struct Processor {
    pub current_tid: ThreadID,
    pub current_thread: Option<Arc<Mutex<Thread>>>,
}

impl Processor {
    pub const fn new() -> Self {
        Self {
            current_tid: -1,
            current_thread: None,
        }
    }
}

pub fn current_tid() -> ThreadID {
    unsafe { PROCESSOR.current_tid }
}

/// 临时获取当前线程
pub fn current_thread() -> &'static mut Arc<Mutex<Thread>> {
    unsafe { PROCESSOR.current_thread.as_mut().unwrap() }
}
