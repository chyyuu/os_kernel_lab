//! 为进程提供系统调用等内核功能

mod condvar;
mod fs;
mod syscall;
mod process;

use crate::interrupt::*;
use crate::process::*;
use alloc::sync::Arc;
use spin::Mutex;
pub(self) use syscall::*;
pub(self) use fs::*;
pub(self) use process::*;

pub use condvar::Condvar;
pub use syscall::syscall_handler;