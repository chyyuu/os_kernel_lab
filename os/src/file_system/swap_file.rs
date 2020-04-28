//! 用于页面交换，保存内存数据的文件 [`SWAP_FILE`](SwapFile)

use super::*;
use crate::data_structure::{Allocator, SegmentTreeAllocator};
use crate::process::ThreadID;
use hashbrown::HashMap;
use lazy_static::*;
use spin::Mutex;

lazy_static! {
    /// 用于页面交换，保存内存数据的文件
    pub static ref SWAP_FILE: Mutex<SwapFile<SegmentTreeAllocator>> = Mutex::new(SwapFile::new(
        Range::from(HDD_START_ADDRESS..HDD_END_ADDRESS)
    ));
}

type Page = [u8; PAGE_SIZE];

/// 页面的唯一标签：线程 ID 和虚拟页号
#[derive(Copy, Clone, Debug, Eq, PartialEq, Hash)]
struct PageID {
    /// 线程 ID
    tid: ThreadID,
    /// 虚拟页号
    vpn: VirtualPageNumber,
}

/// 在一段标记为『硬盘』的物理地址内保存交换页面
///
/// 只是页面的数据保存在『硬盘』上，而元信息、字典均在内核堆中。
pub struct SwapFile<T: Allocator> {
    /// 可以使用的『硬盘』空间
    hdd_space: Range<PhysicalPageNumber>,
    /// 所有在文件中暂存的页面
    saved_pages: HashMap<PageID, PhysicalPageNumber>,
    /// 分配页面
    allocator: T,
}

impl<T: Allocator> SwapFile<T> {
    /// 指定『硬盘』空间，创建交换文件
    pub fn new(hdd_space: Range<PhysicalPageNumber>) -> Self {
        // 计算线段树，其中完全不可使用的区间标 1，[1] 为树根
        Self {
            hdd_space,
            saved_pages: HashMap::with_capacity(hdd_space.len()),
            allocator: T::new(hdd_space.len()),
        }
    }

    /// 保存一个页面
    ///
    /// 如果页面已满，则返回 `Err`
    pub fn save(&mut self, tid: ThreadID, vpn: VirtualPageNumber, page: &Page) -> MemoryResult<()> {
        if self.saved_pages.len() >= self.hdd_space.len() {
            Err("swap file full")
        } else {
            // 分配一个物理页面
            let ppn = self.hdd_space.start + self.allocator.alloc().unwrap();
            self.saved_pages.insert(PageID { tid, vpn }, ppn);
            // 写入数据
            ppn.deref_kernel().copy_from_slice(page);
            Ok(())
        }
    }

    /// 取出一个页面
    pub fn take(&mut self, tid: ThreadID, vpn: VirtualPageNumber) -> Option<&'static Page> {
        if let Some(ppn) = self.saved_pages.remove(&PageID { tid, vpn }) {
            self.allocator.dealloc(ppn - self.hdd_space.start);
            Some(ppn.deref_kernel())
        } else {
            None
        }
    }
}
