//! 内存替换
//!
//! TODO

use crate::memory::{
    address::*,
    config::*,
    frame::{FrameTracker, FRAME_ALLOCATOR},
};
use alloc::{collections::LinkedList, vec::Vec};

/// 映射关系的缩写
type Pair = (VirtualPageNumber, FrameTracker);

/// 页面置换
///
/// 保存了目前正在被使用的所有映射关系，**保存了所有的 `FrameTracker`**
pub struct Swapper {
    /// 这个线程允许使用的物理页面数量
    frame_limit: usize,
    /// 正在使用的所有映射关系
    active_pairs: LinkedList<Pair>,
}

/// FIFO 的页面置换
impl Swapper {
    /// 创建
    pub fn new(frame_limit: usize, allocated_pairs: impl Iterator<Item = Pair>) -> Self {
        Self {
            frame_limit,
            active_pairs: allocated_pairs.collect(),
        }
    }

    /// 选择一个需要被替换的页面，如果不需替换返回 None
    ///
    /// 注意同时会返回 [`FrameTracker`]
    pub fn choose_victim(&mut self) -> Option<Pair> {
        assert!(self.active_pairs.len() <= self.frame_limit);
        if self.active_pairs.len() == self.frame_limit && self.frame_limit > 0 {
            self.active_pairs.pop_front()
        } else {
            None
        }
    }

    /// 添加一个映射
    pub fn add_pair(&mut self, pair: Pair) {
        assert!(self.choose_victim().is_none());
        self.active_pairs.push_back(pair);
    }

    /// 目前正使用的映射数量
    pub fn len(&self) -> usize {
        self.active_pairs.len()
    }
}
