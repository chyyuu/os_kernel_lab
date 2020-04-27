//! 线程的所有控制信息 [`Thread`]

use super::*;
use crate::memory::{MemorySet};

pub struct Thread {
    pub thread_id: ThreadID,
    pub memory_set: MemorySet,
}