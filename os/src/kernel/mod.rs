//! 为进程提供系统调用等内核功能

mod condvar;
mod fs;
mod syscall;
mod process;

use crate::interrupt::*;
use crate::memory::*;
use crate::process::*;
use alloc::sync::Arc;
use spin::Mutex;
pub(self) use syscall::*;

pub use condvar::Condvar;
pub use syscall::syscall_handler;
pub use fs::*;
pub use process::*;