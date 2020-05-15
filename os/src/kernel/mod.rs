//! 为进程提供系统调用等内核功能

mod condvar;
mod syscall;

use crate::interrupt::*;
use crate::memory::*;
use crate::process::*;
use spin::Mutex;
use alloc::sync::Arc;

pub use condvar::Condvar;