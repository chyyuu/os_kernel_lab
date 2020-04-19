//! 表示一个页面区间，提供迭代器功能

/// 表示一段连续的页面
#[derive(Clone, Copy, Debug)]
pub struct Range<T: From<usize> + Into<usize> + Copy> {
    start: T,
    end: T,
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
    /// 检测两个 [`PageRange`] 是否存在重合的区间
    pub fn overlap_with(&self, other: &Range<T>) -> bool {
        self.start.into() < other.end.into() && self.end.into() > other.start.into()
    }

    /// 迭代区间中的所有页
    pub fn iter(&self) -> impl Iterator<Item = T> {
        (self.start.into()..self.end.into()).map(T::from)
    }
}

/// 支持物理 / 虚拟页面区间互相转换
impl<T: From<usize> + Into<usize> + Copy> Range<T> {
    pub fn into<U: From<usize> + Into<usize> + Copy + From<T>>(self) -> Range<U> {
        Range::<U> {
            start: U::from(self.start),
            end: U::from(self.end),
        }
    }
}