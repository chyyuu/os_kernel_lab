//! 单一页表页面（4K） [`PageTable`]，以及相应封装 [`FrameTracker`] 的 [`PageTableTracker`]
//!
//! 每个页表中包含 512 条页表项
//!
//! # 页表工作方式
//! 1.  首先从 `satp` 中获取页表根节点的页号，找到根页表
//! 2.  对于虚拟地址中每一级 VPN（9 位），在对应的页表中找到对应的页表项
//! 3.  如果对应项 Valid 位为 0，则发生 Page Fault
//! 4.  如果对应项 Readable / Writable 位为 1，则表示这是一个叶子节点。
//!     页表项中的值便是虚拟地址对应的物理页号
//!     如果此时还没有达到最低级的页表，说明这是一个大页
//! 5.  将页表项中的页号作为下一级查询目标，查询直到达到最低级的页表，最终得到页号

use super::page_table_entry::PageTableEntry;
use crate::memory::{address::*, config::PAGE_SIZE, frame::FrameTracker};
/// 存有 512 个页表项的页表
///
/// 注意我们不会使用常规的 Rust 语法来创建 `PageTable`。相反，我们会分配一个物理页，
/// 其对应了一段物理内存，然后直接把其当做页表进行读写。我们会在操作系统中用一个「指针」
/// [`PageTableTracker`] 来记录这个页表。
#[repr(C)]
pub struct PageTable {
    pub entries: [PageTableEntry; PAGE_SIZE / 8],
}

impl PageTable {
    /// 将页表清零
    pub fn zero_init(&mut self) {
        self.entries = [Default::default(); PAGE_SIZE / 8];
    }
}

/// 类似于 [`FrameTracker`]，用于记录某一个内存中页表
///
/// 注意到，「真正的页表」会放在我们分配出来的物理页当中，而不应放在操作系统的运行栈或堆中。
/// 而 `PageTableTracker` 会保存在某个线程的元数据中（也就是在操作系统的堆上），指向其真正的页表。
///
/// 当 `PageTableTracker` 被 drop 时，会自动 drop `FrameTracker`，进而释放帧。
pub struct PageTableTracker(pub FrameTracker);

impl PageTableTracker {
    /// 将一个分配的帧清零，形成空的页表
    pub fn new(frame: FrameTracker) -> Self {
        let mut page_table = Self(frame);
        page_table.zero_init();
        page_table
    }
    /// 获取物理页号
    pub fn page_number(&self) -> PhysicalPageNumber {
        self.0.page_number()
    }
}

// PageTableEntry 和 PageTableTracker 都可以 deref 到对应的 PageTable
// （使用线性映射来访问相应的物理地址）

impl core::ops::Deref for PageTableTracker {
    type Target = PageTable;
    fn deref(&self) -> &Self::Target {
        self.0.address().deref_kernel()
    }
}

impl core::ops::DerefMut for PageTableTracker {
    fn deref_mut(&mut self) -> &mut Self::Target {
        self.0.address().deref_kernel()
    }
}

// 因为 PageTableEntry 和具体的 PageTable 之间没有生命周期关联，所以返回 'static 引用方便写代码
impl PageTableEntry {
    pub fn get_next_table(&self) -> &'static mut PageTable {
        self.address().deref_kernel()
    }
}
