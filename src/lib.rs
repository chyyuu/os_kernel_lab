extern crate alloc;
use alloc::sync::{Arc, Weak};
use core::any::Any;

use core::fmt::{Debug, Formatter, Result};

pub trait BlockDevice: Send + Sync + Any {
    fn read_block(&self, block_id: usize, buf: &mut [u8]);
    fn write_block(&self, block_id: usize, buf: &[u8]);
}

pub const BLOCK_SZ: usize = 512;

//------------------------efs-----------------------------------
//------------------------block cache -----------------------
use alloc::collections::BTreeMap;
use lazy_static::*;
use spin::Mutex;

pub struct BlockCache {
    cache: [u8; BLOCK_SZ],
    block_id: usize,
    block_device: Arc<dyn BlockDevice>,
}

impl BlockCache {
    pub fn new(block_id: usize, block_device: Arc<dyn BlockDevice>) -> Self {
        let mut cache = [0u8; BLOCK_SZ];
        block_device.read_block(block_id, &mut cache);
        Self {
            cache,
            block_id,
            block_device,
        }
    }
    pub fn start_addr(&self, offset: usize) -> usize {
        &self.cache[offset] as *const _ as usize
    }
}

impl Drop for BlockCache {
    fn drop(&mut self) {
        // write back
        self.block_device.write_block(self.block_id, &self.cache);
        // invalid in block cache manager
        BLOCK_CACHE_MANAGER.lock().invalid(self.block_id);
    }
}

pub struct BlockCacheManager {
    map: BTreeMap<usize, Weak<BlockCache>>,
}

lazy_static! {
    static ref BLOCK_CACHE_MANAGER: Mutex<BlockCacheManager> = Mutex::new(
        BlockCacheManager::new()
    );
}

impl BlockCacheManager {
    pub fn new() -> Self {
        Self { map: BTreeMap::new() }
    }
    pub fn get(
        &mut self,
        block_id: usize,
        block_device: Arc<dyn BlockDevice>
    ) -> Arc<BlockCache> {
        if let Some(block_cache) = self.map.get(&block_id) {
            // return cloned
            block_cache.upgrade().unwrap().clone()
        } else {
            // fetch from disk
            let block_cache = Arc::new(BlockCache::new(
                block_id,
                block_device.clone()
            ));
            self.map.insert(
                block_id,
                Arc::downgrade(&block_cache),
            );
            // return
            block_cache
        }
    }
    pub fn invalid(&mut self, block_id: usize) {
        assert!(self.map.remove(&block_id).is_some());
    }
}

pub fn get_block_cache(
    block_id: usize,
    block_device: Arc<dyn BlockDevice>
) -> Arc<BlockCache> {
    BLOCK_CACHE_MANAGER.lock().get(block_id, block_device)
}
//---------dirty cache-----------------------
use core::marker::PhantomData;

pub struct Dirty<T> {
    block_cache: Arc<BlockCache>,
    offset: usize,
    phantom: PhantomData<T>,
}

impl<T> Dirty<T>
where
    T: Sized,
{
    pub fn new(block_id: usize, offset: usize, block_device: Arc<dyn BlockDevice>) -> Self {
        Self {
            block_cache: get_block_cache(block_id, block_device.clone()),
            offset,
            phantom: PhantomData,
        }
    }
    pub fn get_mut(&mut self) -> &mut T {
        let type_size = core::mem::size_of::<T>();
        // assert that the struct is inside a block
        assert!(self.offset + type_size <= BLOCK_SZ);
        let start_addr = self.block_cache.start_addr(self.offset);
        unsafe { &mut *(start_addr as *mut T) }
    }
    pub fn get_ref(&self) -> &T {
        let type_size = core::mem::size_of::<T>();
        // assert that the struct is inside a block
        assert!(self.offset + type_size <= BLOCK_SZ);
        let start_addr = self.block_cache.start_addr(self.offset);
        unsafe { &*(start_addr as *const T) }
    }
    pub fn read<V>(&self, f: impl FnOnce(&T) -> V) -> V {
        f(self.get_ref())
    }
    pub fn modify<V>(&mut self, f: impl FnOnce(&mut T) -> V) -> V {
        f(self.get_mut())
    }
}
//-----------bitmap---------------------------------

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
    (block_pos, bit / 64, bit % 64)
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
                block_device.clone(),
            );
            let bitmap_block = dirty_bitmap_block.get_mut();
            if let Some((bits64_pos, inner_pos)) = bitmap_block
                .iter()
                .enumerate()
                .find(|(_, bits64)| **bits64 != u64::MAX)
                .map(|(bits64_pos, bits64)| (bits64_pos, bits64.trailing_ones() as usize))
            {
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
        let mut dirty_bitmap_block: Dirty<BitmapBlock> =
            Dirty::new(block_pos + self.start_block_id, 0, block_device.clone());
        dirty_bitmap_block.modify(|bitmap_block| {
            assert!(bitmap_block[bits64_pos] & (1u64 << inner_pos) > 0);
            bitmap_block[bits64_pos] -= 1u64 << inner_pos;
        });
    }
    pub fn maximum(&self) -> usize {
        self.blocks * BLOCK_BITS
    }
}
//----------------------efs-------------------------------
pub struct EasyFileSystem {
    pub block_device: Arc<dyn BlockDevice>,
    pub inode_bitmap: Bitmap,
    pub data_bitmap: Bitmap,
    inode_area_start_block: u32,
    data_area_start_block: u32,
}

type DataBlock = [u8; BLOCK_SZ];

impl EasyFileSystem {
    pub fn create(
        block_device: Arc<dyn BlockDevice>,
        total_blocks: u32,
        inode_bitmap_blocks: u32,
    ) -> Arc<Mutex<Self>> {
        // calculate block size of areas & create bitmaps
        let inode_bitmap = Bitmap::new(1, inode_bitmap_blocks as usize);
        let inode_num = inode_bitmap.maximum();
        let inode_area_blocks =
            ((inode_num * core::mem::size_of::<DiskInode>() + BLOCK_SZ - 1) / BLOCK_SZ) as u32;
        let inode_total_blocks = inode_bitmap_blocks + inode_area_blocks;
        let data_total_blocks = total_blocks - 1 - inode_total_blocks;
        let data_bitmap_blocks = (data_total_blocks + 4096) / 4097;
        let data_area_blocks = data_total_blocks - data_bitmap_blocks;
        let data_bitmap = Bitmap::new(
            (1 + inode_bitmap_blocks + inode_area_blocks) as usize,
            data_bitmap_blocks as usize,
        );
        let mut efs = Self {
            block_device,
            inode_bitmap,
            data_bitmap,
            inode_area_start_block: 1 + inode_bitmap_blocks,
            data_area_start_block: 1 + inode_total_blocks + data_bitmap_blocks,
        };
        // clear all blocks
        for i in 0..total_blocks {
            efs.get_block(i).modify(|data_block| {
                for byte in data_block.iter_mut() {
                    *byte = 0;
                }
            });
        }
        // initialize SuperBlock
        efs.get_super_block().modify(|super_block| {
            super_block.initialize(
                total_blocks,
                inode_bitmap_blocks,
                inode_area_blocks,
                data_bitmap_blocks,
                data_area_blocks,
            );
        });
        // write back immediately
        // create a inode for root node "/"
        //assert_eq!(efs.alloc_inode(), 0);
        // efs.get_disk_inode(0).modify(|disk_inode| {
        //     disk_inode.initialize(DiskInodeType::Directory, efs.alloc_data());
        // });
        Arc::new(Mutex::new(efs))
    }

    fn get_super_block(&self) -> Dirty<SuperBlock> {
        Dirty::new(0, 0, self.block_device.clone())
    }

    fn get_block(&self, block_id: u32) -> Dirty<DataBlock> {
        Dirty::new(
            block_id as usize,
            0,
            self.block_device.clone(),
        )
    }
}

const EFS_MAGIC: u32 = 0x3b800001;
const INODE_DIRECT_COUNT: usize = 60;
const NAME_LENGTH_LIMIT: usize = 27;

fn u32tou8(v: u32) -> [u8; 4] {
    unsafe {
        let u32Ptr: *const u32 = &v as *const u32;
        let u8Ptr: *const u8 = u32Ptr as *const u8;
        return [
            *u8Ptr.offset(0),
            *u8Ptr.offset(1),
            *u8Ptr.offset(2),
            *u8Ptr.offset(3),
        ];
    }
}

fn u8tou32(v: [u8; 4]) -> u32 {
    if v.len() < 4 {
        return 0;
    }
    unsafe {
        let u32Ptr: *const u32 = v.as_ptr() as *const u32;
        return *u32Ptr;
    }
    return 0;
}

#[repr(C)]
pub struct SuperBlock {
    magic: u32,
    pub total_blocks: u32,
    pub inode_bitmap_blocks: u32,
    pub inode_area_blocks: u32,
    pub data_bitmap_blocks: u32,
    pub data_area_blocks: u32,
}

impl Debug for SuperBlock {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result {
        f.debug_struct("SuperBlock")
            .field("total_blocks", &self.total_blocks)
            .field("inode_bitmap_blocks", &self.inode_bitmap_blocks)
            .field("inode_area_blocks", &self.inode_area_blocks)
            .field("data_bitmap_blocks", &self.data_bitmap_blocks)
            .field("data_area_blocks", &self.data_area_blocks)
            .finish()
    }
}

impl SuperBlock {
    pub fn initialize(
        &mut self,
        total_blocks: u32,
        inode_bitmap_blocks: u32,
        inode_area_blocks: u32,
        data_bitmap_blocks: u32,
        data_area_blocks: u32,
    ) {
        *self = Self {
            magic: EFS_MAGIC,
            total_blocks,
            inode_bitmap_blocks,
            inode_area_blocks,
            data_bitmap_blocks,
            data_area_blocks,
        }
    }
    pub fn is_valid(&self) -> bool {
        self.magic == EFS_MAGIC
    }
}

#[derive(PartialEq)]
pub enum DiskInodeType {
    File,
    Directory,
}

#[repr(C)]
/// Only support level-1 indirect now, **indirect2** field is always 0.
pub struct DiskInode {
    pub size: u32,
    pub direct: [u32; INODE_DIRECT_COUNT],
    pub indirect1: u32,
    pub indirect2: u32,
    type_: DiskInodeType,
}
