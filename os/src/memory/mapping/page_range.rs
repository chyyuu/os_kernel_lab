//! 表示一个虚拟页面区间

use crate::memory::{
    address::*,
    mapping::page_table_entry::{PageTableEntry, Flags},
};

/// 表示一段连续的虚拟页面
#[derive(Clone, Debug)]
pub struct PageRange {
    pub start_page_number: VirtualPageNumber,
    pub end_page_number: VirtualPageNumber,
}

impl PageRange {
    /// 创建一个区间
    pub fn new(range: core::ops::Range<VirtualPageNumber>) -> Self {
        Self {
            start_page_number: range.start,
            end_page_number: range.end,
        }
    }
    /// 检测两个 [`PageRange`] 是否存在重合的区间
    pub fn overlap_with(&self, other: &PageRange) -> bool {
        self.start_page_number < other.end_page_number && self.end_page_number > other.start_page_number
    }

    /// 迭代区间中的所有虚拟页
    pub fn iter(&self) -> PageRangeIterator {
        PageRangeIterator {
            page_number: self.start_page_number,
            end_page_number: self.end_page_number,
        }
    }
}

/// [`PageRange`] 的迭代器
#[derive(Clone, Copy, Debug)]
pub struct PageRangeIterator {
    page_number: VirtualPageNumber,
    end_page_number: VirtualPageNumber,
}

impl Iterator for PageRangeIterator {
    type Item = VirtualPageNumber;
    fn next(&mut self) -> Option<Self::Item> {
        if self.page_number == self.end_page_number {
            None
        } else {
            let page_number = self.page_number;
            self.page_number += 1;
            Some(page_number)
        }
    }
}