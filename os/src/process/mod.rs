//! 进程 / 线程管理

mod processor;
mod thread;

pub type ThreadID = isize;

pub use processor::{PROCESSOR, current_thread, current_tid};
pub use thread::Thread;