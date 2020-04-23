//! 内存映射
//! 
//! 每个线程保存一个 [`Mapping`]，其中记录了所有的字段 [`Segment`]。
//! 同时，也要追踪为页表或字段分配的所有物理帧，目的是 drop 掉之后可以安全释放所有资源。


mod range;
mod page_table_entry;
mod page_table;
mod segment;
mod mapping;
mod memory_set;
mod swapper;

pub use page_table_entry::{PageTableEntry, Flags};
pub use page_table::{PageTable, PageTableTracker};
pub use range::Range;
pub use segment::{Segment, MapType};
pub use mapping::Mapping;
pub use memory_set::MemorySet;
pub use swapper::Swapper;