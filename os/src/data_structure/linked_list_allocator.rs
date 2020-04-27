//! 提供列表实现的分配器 [`LinkedListAllocator`]

use super::Allocator;
use alloc::{vec, vec::Vec};

/// 使用列表实现分配器
/// 
/// 在列表末尾进行加入 / 删除。
/// 
/// 每个元素 tuple `(start, end)` 表示 [start, end) 区间为可用。
pub struct LinkedListAllocator {
    list: Vec<(usize, usize)>,
}

impl Allocator for LinkedListAllocator {
    fn new(capacity: usize) -> Self {
        Self {
            list: vec![(0, capacity)]
        }
    }

    fn alloc(&mut self) -> Option<usize> {
        if let Some((start, end)) = self.list.pop() {
            if end - start > 1 {
                self.list.push((start + 1, end));
            }
            Some(start)
        } else {
            None
        }
    }

    fn dealloc(&mut self, index: usize) {
        self.list.push((index, index + 1));
    }
}