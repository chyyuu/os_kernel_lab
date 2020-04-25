//! 线程

use super::*;
use crate::memory::{MemorySet};

pub struct Thread {
    pub thread_id: ThreadID,
    pub memory_set: MemorySet,
}