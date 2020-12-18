use alloc::sync::Arc;
use super::BlockDevice;
use super::Dirty;
use super::BLOCK_SZ;

type BitmapBlock = [u64; 64];

const BLOCK_BITS: usize = BLOCK_SZ * 8;

pub struct Bitmap {
    start_block_id: usize,
    blocks: usize,
}

/// Return (block_pos, bits64_pos, inner_pos)
fn decomposition(mut bit: usize) -> (usize, usize, usize) {
    let block_pos = bit / BLOCK_BITS;
    bit = bit % BLOCK_BITS;
    (block_pos, bit/64, bit % 64)
}

impl Bitmap {
    pub fn new(start_block_id: usize, blocks: usize) -> Self {
        Self {
            start_block_id,
            blocks,
        }
    }
    pub fn alloc(&self, block_device: &Arc<dyn BlockDevice>) -> Option<usize> {
        for block_id in 0..self.blocks {
            let mut dirty_bitmap_block: Dirty<BitmapBlock> = Dirty::new(
                block_id + self.start_block_id as usize,
                0,
                block_device.clone()
            );
            let bitmap_block = dirty_bitmap_block.get_mut();
            if let Some((bits64_pos, inner_pos)) = bitmap_block
                .iter()
                .enumerate()
                .find(|(_, bits64)| **bits64 != u64::MAX)
                .map(|(bits64_pos, bits64)| {
                    (bits64_pos, bits64.trailing_ones() as usize)
                }) {
                // modify cache
                bitmap_block[bits64_pos] |= 1u64 << inner_pos;
                return Some(block_id * BLOCK_BITS + bits64_pos * 64 + inner_pos as usize);
                // after dirty is dropped, data will be written back automatically
            }
        }
        None
    }
    pub fn dealloc(&self, block_device: &Arc<dyn BlockDevice>, bit: usize) {
        let (block_pos, bits64_pos, inner_pos) = decomposition(bit);
        let mut dirty_bitmap_block: Dirty<BitmapBlock> = Dirty::new(
            block_pos,
            0,
            block_device.clone(),
        );
        dirty_bitmap_block.modify(|bitmap_block| {
            assert!(bitmap_block[bits64_pos] & (1u64 << inner_pos) > 0);
            bitmap_block[bits64_pos] -= 1u64 << inner_pos;
        });
    }
    pub fn maximum(&self) -> usize {
        self.blocks * BLOCK_BITS
    }
}