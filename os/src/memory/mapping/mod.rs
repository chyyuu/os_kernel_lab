//! 内存映射
//!
//! 每个线程保存一个 [`Mapping`]，其中记录了所有的字段 [`Segment`]。
//! 同时，也要追踪为页表或字段分配的所有物理页，目的是 drop 掉之后可以安全释放所有资源。

#[allow(clippy::module_inception)]
mod mapping;
mod memory_set;
mod page_table;
mod page_table_entry;
mod segment;

pub use mapping::Mapping;
pub use memory_set::MemorySet;
pub use page_table::{PageTable, PageTableTracker};
pub use page_table_entry::{Flags, PageTableEntry};
pub use segment::{MapType, Segment};
