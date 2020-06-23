//! 为进程提供系统调用等内核功能

mod condvar;
mod fs;
mod process;
mod syscall;

use crate::interrupt::*;
use crate::process::*;
use alloc::sync::Arc;
pub(self) use fs::*;
pub(self) use process::*;
use spin::Mutex;
pub(self) use syscall::*;

pub use condvar::Condvar;
pub use syscall::syscall_handler;
