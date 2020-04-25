mod segment_tree;

pub use segment_tree::SegmentTree;

pub trait Allocator {
    fn new(capacity: usize) -> Self;
    fn alloc(&mut self) -> Option<usize>;
    fn dealloc(&mut self, index: usize);
}