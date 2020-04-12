//! 使用线性查找分配帧

use spin::Mutex;
use super::address::*;

pub struct FrameAllocator {
    flags: [u8; 4096],
}

impl Default for FrameAllocator {
    fn default() -> Self {
        let obj = FrameAllocator{ flags: [0; 4096] };
        // here
        obj
    }
}

impl FrameAllocator {
    fn get_bit(&self, ppn: PPN) -> bool {
        (self.flags[ppn.0 / 8] & (1 << (ppn.0 % 8))) != 0
    }
    fn set_bit(&mut self, ppn: PPN, value: bool) {
        if self.get_bit(ppn) != value {
            self.flags[ppn.0 / 8] ^= 1 << (ppn.0 % 8);
        }
    }
}

pub struct Frame {
    
}