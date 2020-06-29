//! 表示一个页面区间 [`Range`]，提供迭代器功能

/// 表示一段连续的页面
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct Range<T: From<usize> + Into<usize> + Copy> {
    pub start: T,
    pub end: T,
}

/// 创建一个区间
impl<T: From<usize> + Into<usize> + Copy, U: Into<T>> From<core::ops::Range<U>> for Range<T> {
    fn from(range: core::ops::Range<U>) -> Self {
        Self {
            start: range.start.into(),
            end: range.end.into(),
        }
    }
}

impl<T: From<usize> + Into<usize> + Copy> Range<T> {
    /// 检测两个 [`Range`] 是否存在重合的区间
    pub fn overlap_with(&self, other: &Range<T>) -> bool {
        self.start.into() < other.end.into() && self.end.into() > other.start.into()
    }

    /// 迭代区间中的所有页
    pub fn iter(&self) -> impl Iterator<Item = T> {
        (self.start.into()..self.end.into()).map(T::from)
    }

    /// 区间大小
    pub fn len(&self) -> usize {
        self.end.into() - self.start.into()
    }

    /// 支持物理 / 虚拟页面区间互相转换
    pub fn into<U: From<usize> + Into<usize> + Copy + From<T>>(self) -> Range<U> {
        Range::<U> {
            start: U::from(self.start),
            end: U::from(self.end),
        }
    }

    /// 从区间中用下标取元素
    pub fn get(&self, index: usize) -> T {
        assert!(index < self.len());
        T::from(self.start.into() + index)
    }

    /// 区间是否包含指定的值
    pub fn contains(&self, value: T) -> bool {
        self.start.into() <= value.into() && value.into() < self.end.into()
    }
}
