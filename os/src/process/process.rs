//! 进程 [`Process`]

use super::*;

/// 进程的信息
pub struct Process {
    /// 是否属于用户态
    pub is_user: bool,
    /// 进程中的线程公用页表 / 内存映射
    pub memory_set: MemorySet,
}

impl Process {
    /// 创建一个内核进程
    pub fn new_kernel() -> MemoryResult<Arc<RwLock<Self>>> {
        Ok(Arc::new(RwLock::new(Self {
            is_user: false,
            memory_set: MemorySet::new_kernel()?,
        })))
    }

    /// 返回用 [`Flags`] 类型表示的用户态信息
    fn user_flag(&self) -> Flags {
        if self.is_user {
            Flags::USER
        } else {
            Flags::empty()
        }
    }

    /// 分配一定数量的连续虚拟空间
    ///
    /// 从 `memory_set` 中找到一段给定长度的未占用虚拟地址空间，分配物理页面并建立映射。返回对应的页面区间。
    ///
    /// `flags` 只需包括 rwx 权限，user 位会根据进程而定。
    pub fn alloc_page_range(
        &mut self,
        size: usize,
        flags: Flags,
    ) -> MemoryResult<Range<VirtualAddress>> {
        // memory_set 只能按页分配，所以让 size 向上取整页
        let alloc_size = (size + PAGE_SIZE - 1) & !(PAGE_SIZE - 1);
        // 从 memory_set 中找一段不会发生重叠的空间
        let mut range = Range::<VirtualAddress>::from(0..alloc_size);
        while self.memory_set.overlap_with(range.into()) {
            range.start += alloc_size;
            range.end += alloc_size;
        }
        // 分配物理页面，建立映射
        self.memory_set.add_segment(Segment {
            map_type: MapType::Framed,
            page_range: range.into(),
            flags: flags | self.user_flag(),
        })?;
        // 返回地址区间（使用参数 size，而非向上取整的 alloc_size）
        Ok(Range::from(range.start..(range.start + size)))
    }
}
