//! 内存映射
//! 
//! 每个线程保存一个 [`Mapping`]，其中记录了所有的字段 [`Segment`]。
//! 同时，也要追踪为页表或字段分配的所有物理帧，目的是 drop 掉之后可以安全释放所有资源。


pub mod page_table_entry;
pub mod page_table;
pub mod page_range;
pub mod segment;
pub mod mapping;

pub use page_table_entry::{PageTableEntry, Flags};
pub use page_table::{PageTable, PageTableTracker};
pub use page_range::PageRange;
pub(self) use segment::Segment;
pub use mapping::Mapping;