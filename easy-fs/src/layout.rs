use core::fmt::{Debug, Formatter, Result};
use super::{
    BLOCK_SZ,
    BlockDevice,
    get_block_cache,
};
use alloc::sync::Arc;
use alloc::vec::Vec;

const EFS_MAGIC: u32 = 0x3b800001;
const INODE_DIRECT_COUNT: usize = 60;
const NAME_LENGTH_LIMIT: usize = 27;

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
    #[allow(unused)]
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
            get_block_cache(self.indirect1 as usize, Arc::clone(block_device))
                .lock()
                .read(0, |indirect_block: &IndirectBlock| {
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
        get_block_cache(
            self.indirect1 as usize,
            Arc::clone(block_device)
        )
        .lock()
        .modify(0, |indirect_block: &mut IndirectBlock| {
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
            get_block_cache(
                self.indirect1 as usize,
                Arc::clone(block_device),
            )
            .lock()
            .modify(0, |indirect_block: &mut IndirectBlock| {
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
            get_block_cache(
                self.get_block_id(start_block as u32, block_device) as usize,
                Arc::clone(block_device),
            )
            .lock()
            .read(0, |data_block: &DataBlock| {
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
            get_block_cache(
                self.get_block_id(start_block as u32, block_device) as usize,
                Arc::clone(block_device)
            )
            .lock()
            .modify(0, |data_block: &mut DataBlock| {
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

#[repr(C)]
pub struct DirEntry {
    name: [u8; NAME_LENGTH_LIMIT + 1],
    inode_number: u32,
}

pub const DIRENT_SZ: usize = 32;

//pub type DirentBlock = [DirEntry; BLOCK_SZ / DIRENT_SZ];
pub type DirentBytes = [u8; DIRENT_SZ];

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