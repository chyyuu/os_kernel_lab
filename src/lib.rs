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
use spin::{Mutex,MutexGuard};

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
        assert_eq!(efs.alloc_inode(), 0);
        efs.get_disk_inode(0).modify(|disk_inode| {
            disk_inode.initialize(DiskInodeType::Directory, efs.alloc_data());
        });
        Arc::new(Mutex::new(efs))
    }

    pub fn root_inode(efs: &Arc<Mutex<Self>>) -> Inode {
        Inode::new(
            0,
            efs.clone(),
            efs.lock().block_device.clone(),
        )
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

    pub fn get_disk_inode(&self, inode_id: u32) -> Dirty<DiskInode> {
        let inode_size = core::mem::size_of::<DiskInode>();
        let inodes_per_block = (BLOCK_SZ / inode_size) as u32;
        let block_id = self.inode_area_start_block + inode_id / inodes_per_block;
        Dirty::new(
            block_id as usize,
            (inode_id % inodes_per_block) as usize * inode_size,
            self.block_device.clone(),
        )
    }
    pub fn alloc_inode(&mut self) -> u32 {
        self.inode_bitmap.alloc(&self.block_device).unwrap() as u32
    }

    /// Return a block ID not ID in the data area.
    pub fn alloc_data(&mut self) -> u32 {
        self.data_bitmap.alloc(&self.block_device).unwrap() as u32 + self.data_area_start_block
    }

    pub fn dealloc_data(&mut self, block_id: u32) {
        self.data_bitmap.dealloc(
            &self.block_device,
            (block_id - self.data_area_start_block) as usize
        )
    }
}
//----------------------fs layout -----------------------------------------
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

type IndirectBlock = [u32; BLOCK_SZ / 4];
type DataBlock = [u8; BLOCK_SZ];

#[repr(C)]
/// Only support level-1 indirect now, **indirect2** field is always 0.
pub struct DiskInode {
    pub size: u32,
    pub direct: [u32; INODE_DIRECT_COUNT],
    pub indirect1: u32,
    pub indirect2: u32,
    type_: DiskInodeType,
}

impl DiskInode {
    /// indirect1 block is allocated when the file is created.
    pub fn initialize(&mut self, type_: DiskInodeType, indirect1: u32) {
        self.size = 0;
        self.direct.iter_mut().for_each(|v| *v = 0);
        self.indirect1 = indirect1;
        self.indirect2 = 0;
        self.type_ = type_;
    }
    pub fn is_dir(&self) -> bool {
        self.type_ == DiskInodeType::Directory
    }
    pub fn is_file(&self) -> bool {
        self.type_ == DiskInodeType::File
    }
    pub fn blocks(&self) -> u32 {
        Self::_blocks(self.size)
    }
    fn _blocks(size: u32) -> u32 {
        (size + BLOCK_SZ as u32 - 1) / BLOCK_SZ as u32
    }
    pub fn get_block_id(&self, inner_id: u32, block_device: &Arc<dyn BlockDevice>) -> u32 {
        let inner_id = inner_id as usize;
        if inner_id < INODE_DIRECT_COUNT {
            self.direct[inner_id]
        } else {
            // only support indirect1 now
            Dirty::<IndirectBlock>::new(
                self.indirect1 as usize,
                0,
                block_device.clone()
            ).read(|indirect_block| {
                // it will panic if file is too large
                indirect_block[inner_id - INODE_DIRECT_COUNT]
            })
        }
    }
    pub fn blocks_num_needed(&self, new_size: u32) -> u32 {
        assert!(new_size >= self.size);
        Self::_blocks(new_size) - self.blocks()
    }
    pub fn increase_size(
        &mut self,
        new_size: u32,
        new_blocks: Vec<u32>,
        block_device: &Arc<dyn BlockDevice>,
    ) {
        assert_eq!(new_blocks.len() as u32, self.blocks_num_needed(new_size));
        let last_blocks = self.blocks();
        self.size = new_size;
        let current_blocks = self.blocks();
        Dirty::<IndirectBlock>::new(
            self.indirect1 as usize,
            0,
            block_device.clone()
        ).modify(|indirect_block| {
            for i in 0..current_blocks - last_blocks {
                let inner_id = (last_blocks + i) as usize;
                let new_block = new_blocks[i as usize];
                if inner_id < INODE_DIRECT_COUNT {
                    self.direct[inner_id] = new_block;
                } else {
                    indirect_block[inner_id - INODE_DIRECT_COUNT] = new_block;
                }
            }
        });
    }
    /// Clear size to zero and return blocks that should be deallocated.
    pub fn clear_size(&mut self, block_device: &Arc<dyn BlockDevice>) -> Vec<u32> {
        let mut v: Vec<u32> = Vec::new();
        let blocks = self.blocks() as usize;
        self.size = 0;
        for i in 0..blocks.min(INODE_DIRECT_COUNT) {
            v.push(self.direct[i]);
            self.direct[i] = 0;
        }
        if blocks > INODE_DIRECT_COUNT {
            Dirty::<IndirectBlock>::new(
                self.indirect1 as usize,
                0,
                block_device.clone(),
            ).modify(|indirect_block| {
                for i in 0..blocks - INODE_DIRECT_COUNT {
                    v.push(indirect_block[i]);
                    indirect_block[i] = 0;
                }
            });
        }
        v
    }
    pub fn read_at(
        &self,
        offset: usize,
        buf: &mut [u8],
        block_device: &Arc<dyn BlockDevice>,
    ) -> usize {
        let mut start = offset;
        let end = (offset + buf.len()).min(self.size as usize);
        if start >= end {
            return 0;
        }
        let mut start_block = start / BLOCK_SZ;
        let mut read_size = 0usize;
        loop {
            // calculate end of current block
            let mut end_current_block = (start / BLOCK_SZ + 1) * BLOCK_SZ;
            end_current_block = end_current_block.min(end);
            // read and update read size
            let block_read_size = end_current_block - start;
            let dst = &mut buf[read_size..read_size + block_read_size];
            Dirty::<DataBlock>::new(
                self.get_block_id(start_block as u32, block_device) as usize,
                0,
                block_device.clone()
            ).read(|data_block| {
                let src = &data_block[start % BLOCK_SZ..start % BLOCK_SZ + block_read_size];
                dst.copy_from_slice(src);
            });
            read_size += block_read_size;
            // move to next block
            if end_current_block == end { break; }
            start_block += 1;
            start = end_current_block;
        }
        read_size
    }
    /// File size must be adjusted before.
    pub fn write_at(
        &mut self,
        offset: usize,
        buf: &[u8],
        block_device: &Arc<dyn BlockDevice>,
    ) -> usize {
        let mut start = offset;
        let end = (offset + buf.len()).min(self.size as usize);
        assert!(start <= end);
        let mut start_block = start / BLOCK_SZ;
        let mut write_size = 0usize;
        loop {
            // calculate end of current block
            let mut end_current_block = (start / BLOCK_SZ + 1) * BLOCK_SZ;
            end_current_block = end_current_block.min(end);
            // write and update write size
            let block_write_size = end_current_block - start;
            Dirty::<DataBlock>::new(
                self.get_block_id(start_block as u32, block_device) as usize,
                0,
                block_device.clone()
            ).modify(|data_block| {
                let src = &buf[write_size..write_size + block_write_size];
                let dst = &mut data_block[start % BLOCK_SZ..start % BLOCK_SZ + block_write_size];
                dst.copy_from_slice(src);
            });
            write_size += block_write_size;
            // move to next block
            if end_current_block == end { break; }
            start_block += 1;
            start = end_current_block;
        }
        write_size
    }
}

pub const DIRENT_SZ: usize = 32;
//pub type DirentBlock = [DirEntry; BLOCK_SZ / DIRENT_SZ];
pub type DirentBytes = [u8; DIRENT_SZ];

#[repr(C)]
pub struct DirEntry {
    name: [u8; NAME_LENGTH_LIMIT + 1],
    inode_number: u32,
}

impl DirEntry {
    pub fn new(name: &str, inode_number: u32) -> Self {
        let mut bytes = [0u8; NAME_LENGTH_LIMIT + 1];
        &mut bytes[..name.len()].copy_from_slice(name.as_bytes());
        Self {
            name: bytes,
            inode_number,
        }
    }
    pub fn into_bytes(&self) -> &DirentBytes {
        unsafe {
            &*(self as *const Self as usize as *const DirentBytes)
        }
    }
    pub fn from_bytes(bytes: &DirentBytes) -> &Self {
        unsafe { &*(bytes.as_ptr() as usize as *const Self) }
    }
    #[allow(unused)]
    pub fn from_bytes_mut(bytes: &mut DirentBytes) -> &mut Self {
        unsafe {
            &mut *(bytes.as_mut_ptr() as usize as *mut Self)
        }
    }
    pub fn name(&self) -> &str {
        let len = (0usize..).find(|i| self.name[*i] == 0).unwrap();
        core::str::from_utf8(&self.name[..len]).unwrap()
    }
    pub fn inode_number(&self) -> u32 {
        self.inode_number
    }
}

//---------------------inode info -----------------------------------
pub struct Inode {
    inode_id: u32,
    fs: Arc<Mutex<EasyFileSystem>>,
    block_device: Arc<dyn BlockDevice>,
}

impl Inode {
    pub fn new(
        inode_id: u32,
        fs: Arc<Mutex<EasyFileSystem>>,
        block_device: Arc<dyn BlockDevice>,
    ) -> Self {
        Self {
            inode_id,
            fs,
            block_device,
        }
    }

    fn get_disk_inode(&self, fs: &mut MutexGuard<EasyFileSystem>) -> Dirty<DiskInode> {
        fs.get_disk_inode(self.inode_id)
    }

    fn find_inode_id(
        &self,
        name: &str,
        inode: &Dirty<DiskInode>,
    ) -> Option<u32> {
        // assert it is a directory
        assert!(inode.read(|inode| inode.is_dir()));
        let file_count = inode.read(|inode| {
            inode.size as usize
        }) / DIRENT_SZ;
        let mut dirent_space: DirentBytes = Default::default();
        for i in 0..file_count {
            assert_eq!(
                inode.read(|inode| {
                    inode.read_at(
                        DIRENT_SZ * i,
                        &mut dirent_space,
                        &self.block_device,
                    )
                }),
                DIRENT_SZ,
            );
            let dirent = DirEntry::from_bytes(&dirent_space);
            if dirent.name() == name {
                return Some(dirent.inode_number() as u32);
            }
        }
        None
    }

    pub fn find(&self, name: &str) -> Option<Arc<Inode>> {
        let mut fs = self.fs.lock();
        let inode = self.get_disk_inode(&mut fs);
        self.find_inode_id(name, &inode)
            .map(|inode_id| {
                Arc::new(Self::new(
                    inode_id,
                    self.fs.clone(),
                    self.block_device.clone(),
                ))
            })
    }

    fn increase_size(
        &self,
        new_size: u32,
        inode: &mut Dirty<DiskInode>,
        fs: &mut MutexGuard<EasyFileSystem>,
    ) {
        let size = inode.read(|inode| inode.size);
        if new_size < size {
            return;
        }
        let blocks_needed = inode.read(|inode| {
            inode.blocks_num_needed(new_size)
        });
        let mut v: Vec<u32> = Vec::new();
        for _ in 0..blocks_needed {
            v.push(fs.alloc_data());
        }
        inode.modify(|inode| {
            inode.increase_size(new_size, v, &self.block_device);
        });
    }

    pub fn create(&self, name: &str) -> Option<Arc<Inode>> {
        let mut fs = self.fs.lock();
        let mut inode = self.get_disk_inode(&mut fs);
        // assert it is a directory
        assert!(inode.read(|inode| inode.is_dir()));
        // has the file been created?
        if let Some(_) = self.find_inode_id(name, &inode) {
            return None;
        }

        // create a new file
        // alloc a inode with an indirect block
        let new_inode_id = fs.alloc_inode();
        let indirect1 = fs.alloc_data();
        // initialize inode
        fs.get_disk_inode(new_inode_id).modify(|inode| {
            inode.initialize(
                DiskInodeType::File,
                indirect1,
            )
        });

        // append file in the dirent
        let file_count =
            inode.read(|inode| inode.size as usize) / DIRENT_SZ;
        let new_size = (file_count + 1) * DIRENT_SZ;
        // increase size
        self.increase_size(new_size as u32, &mut inode, &mut fs);
        // write dirent
        let dirent = DirEntry::new(name, new_inode_id);
        inode.modify(|inode| {
            inode.write_at(
                file_count * DIRENT_SZ,
                dirent.into_bytes(),
                &self.block_device,
            );
        });

        // return inode
        Some(Arc::new(Self::new(
            new_inode_id,
            self.fs.clone(),
            self.block_device.clone(),
        )))
    }

    pub fn ls(&self) -> Vec<String> {
        let mut fs = self.fs.lock();
        let inode = self.get_disk_inode(&mut fs);
        let file_count = inode.read(|inode| {
            (inode.size as usize) / DIRENT_SZ
        });
        let mut v: Vec<String> = Vec::new();
        for i in 0..file_count {
            let mut dirent_bytes: DirentBytes = Default::default();
            assert_eq!(
                inode.read(|inode| {
                    inode.read_at(
                        i * DIRENT_SZ,
                        &mut dirent_bytes,
                        &self.block_device,
                    )
                }),
                DIRENT_SZ,
            );
            v.push(String::from(DirEntry::from_bytes(&dirent_bytes).name()));
        }
        v
    }

    pub fn read_at(&self, offset: usize, buf: &mut [u8]) -> usize {
        let mut fs = self.fs.lock();
        self.get_disk_inode(&mut fs).modify(|disk_inode| {
            disk_inode.read_at(offset, buf, &self.block_device)
        })
    }

    pub fn write_at(&self, offset: usize, buf: &[u8]) -> usize {
        let mut fs = self.fs.lock();
        let mut inode = self.get_disk_inode(&mut fs);
        self.increase_size((offset + buf.len()) as u32, &mut inode, &mut fs);
        inode.modify(|disk_inode| {
            disk_inode.write_at(offset, buf, &self.block_device)
        })
    }

    pub fn clear(&self) {
        let mut fs = self.fs.lock();
        let mut inode = self.get_disk_inode(&mut fs);
        let data_blocks_dealloc = inode.modify(|disk_inode| {
            disk_inode.clear_size(&self.block_device)
        });
        for data_block in data_blocks_dealloc.into_iter() {
            fs.dealloc_data(data_block);
        }
    }
}

