//! 进程 / 线程管理

mod processor;
mod thread;

/// 线程 ID，实际上是 `isize`
pub type ThreadID = isize;

pub use processor::{PROCESSOR, current_thread, current_tid};
pub use thread::Thread;