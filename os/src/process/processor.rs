//! 实现线程的调度和管理 [`Processor`]

use super::*;
use spin::RwLock;
use lazy_static::*;
use alloc::sync::Arc;

lazy_static!{
    pub static ref PROCESSOR: Processor = Processor {
        current_thread: RwLock::new(None),
    };
}

pub struct Processor {
    current_thread: RwLock<Option<Arc<Thread>>>,
}

impl Processor {
    
}