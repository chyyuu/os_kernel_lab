use crate::consts::MAX_PHYSICAL_PAGES;
use spin::Mutex;

pub struct SegmentTreeAllocator {
    a: [u8; MAX_PHYSICAL_PAGES << 1],
    m: usize,
    n: usize,
    offset: usize
}

impl SegmentTreeAllocator {
    pub fn init(&mut self, l: usize, r: usize) {
        self.offset = l - 1;
        self.n = r - l;
        self.m = 1;
        while self.m < self.n + 2 {
            self.m = self.m << 1;
        }
        for i in (1..(self.m << 1)) { self.a[i] = 1; }
        for i in (1..self.n) { self.a[self.m + i] = 0; }
        for i in (1..self.m).rev() { self.a[i] = self.a[i << 1] & self.a[(i << 1) | 1]; }
    }

    pub fn alloc(&mut self) -> usize {
        // assume that we never run out of physical memory
        if self.a[1] == 1 {
            panic!("physical memory depleted!");
        }
        let mut p = 1;
        while p < self.m {
            if self.a[p << 1] == 0 { p = p << 1; } else { p = (p << 1) | 1; }
        }
        let result = p + self.offset - self.m;
        self.a[p] = 1;
        p >>= 1;
        while p > 0 {
            self.a[p] = self.a[p << 1] & self.a[(p << 1) | 1];
            p >>= 1;
        }
        result
    }

    pub fn dealloc(&mut self, n: usize) {
        let mut p = n + self.m - self.offset;
        assert!(self.a[p] == 1);
        self.a[p] = 0;
        p >>= 1;
        while p > 0 {
            self.a[p] = self.a[p << 1] & self.a[(p << 1) | 1];
            p >>= 1;
        }
    }
}

pub static SEGMENT_TREE_ALLOCATOR: Mutex<SegmentTreeAllocator> = Mutex::new(SegmentTreeAllocator {
    a: [0; MAX_PHYSICAL_PAGES << 1],
    m: 0,
    n: 0,
    offset: 0
});
