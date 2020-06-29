//! 管理进程 / 线程

mod config;
mod kernel_stack;
#[allow(clippy::module_inception)]
mod process;
mod processor;
mod thread;

use crate::interrupt::*;
use crate::memory::*;
use alloc::{sync::Arc, vec, vec::Vec};
use spin::{Mutex, RwLock};

pub use config::*;
pub use kernel_stack::KERNEL_STACK;
pub use process::Process;
pub use processor::PROCESSOR;
pub use thread::Thread;
