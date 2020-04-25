//! 内存替换
//!
//! TODO

use crate::memory::{
    address::*,
    config::*,
    frame::{FrameTracker, FRAME_ALLOCATOR},
};
use alloc::{collections::LinkedList, vec::Vec};

pub struct Swapper {
    frame_limit: usize,
    active_pairs: LinkedList<(VirtualPageNumber, FrameTracker)>,
}

/// FIFO 的页面置换
impl Swapper {
    pub fn new(
        frame_limit: usize,
        allocated_pairs: impl Iterator<Item = (VirtualPageNumber, FrameTracker)>,
    ) -> Self {
        let s = Self {
            frame_limit,
            active_pairs: allocated_pairs.collect(),
        };
        println!("size: {}", s.active_pairs.len());
        s
    }

    pub fn test_add(&mut self, pair: (VirtualPageNumber, FrameTracker)) {
        self.active_pairs.push_back(pair)
    }
}
