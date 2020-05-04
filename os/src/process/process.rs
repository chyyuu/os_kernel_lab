//! 进程 [`Process`]

use super::*;
use crate::memory::*;
use alloc::{sync::Arc, vec, vec::Vec};
use spin::RwLock;

/// 进程的信息
pub struct Process {
    /// 属于用户态
    pub is_user: bool,
    /// 进程中的线程公用页表 / 内存映射
    pub memory_set: MemorySet,
    /// 所有线程
    pub threads: Vec<Arc<Thread>>, // 目前没用到
}

impl Process {
    /// 创建一个内核进程
    pub fn new_kernel() -> MemoryResult<Arc<RwLock<Self>>> {
        Ok(Arc::new(RwLock::new(Self {
            is_user: false,
            memory_set: MemorySet::new_kernel()?,
            threads: vec![],
        })))
    }

    /// 添加一个线程
    pub fn push_thread(&mut self, thread: Arc<Thread>) {
        self.threads.push(thread);
    }
}
