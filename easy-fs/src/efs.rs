use alloc::sync::Arc;
use super::{
    BlockDevice,
    Bitmap,
    SuperBlock,
    DiskInode,
    DiskInodeType,
    Dirty,
};
use crate::BLOCK_SZ;

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
    ) -> Self {
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
        let efs = Self {
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
        assert_eq!(efs.inode_bitmap.alloc(&efs.block_device).unwrap(), 0);
        efs.get_disk_inode(0).modify(|disk_inode| {
            disk_inode.initialize(DiskInodeType::Directory);
        });
        efs
    }

    pub fn open(block_device: Arc<dyn BlockDevice>) -> Self {
        // read SuperBlock
        let super_block_dirty: Dirty<SuperBlock> = Dirty::new(0, 0, block_device.clone());
        let super_block = super_block_dirty.read();
        assert!(super_block.is_valid(), "Error loading EFS!");
        println!("{:?}", super_block);
        let inode_total_blocks =
            super_block.inode_bitmap_blocks + super_block.inode_area_blocks;
        let efs = Self {
            block_device,
            inode_bitmap: Bitmap::new(
                1,
                super_block.inode_bitmap_blocks as usize
            ),
            data_bitmap: Bitmap::new(
                (1 + inode_total_blocks) as usize,
                super_block.data_bitmap_blocks as usize,
            ),
            inode_area_start_block: 1 + super_block.inode_bitmap_blocks,
            data_area_start_block: 1 + inode_total_blocks + super_block.data_bitmap_blocks,
        };
        efs
    }

    fn get_super_block(&self) -> Dirty<SuperBlock> {
        Dirty::new(0, 0, self.block_device.clone())
    }

    fn get_disk_inode(&self, inode_id: u32) -> Dirty<DiskInode> {
        let inode_size = core::mem::size_of::<DiskInode>();
        let inodes_per_block = (BLOCK_SZ / inode_size) as u32;
        let block_id = self.inode_area_start_block + inode_id / inodes_per_block;
        Dirty::new(
            block_id as usize,
            (inode_id % inodes_per_block) as usize * inode_size,
            self.block_device.clone(),
        )
    }

    fn get_data_block(&self, data_block_id: u32) -> Dirty<DataBlock> {
        Dirty::new(
            (self.data_area_start_block + data_block_id) as usize,
            0,
            self.block_device.clone(),
        )
    }

    fn get_block(&self, block_id: u32) -> Dirty<DataBlock> {
        Dirty::new(
            block_id as usize,
            0,
            self.block_device.clone(),
        )
    }

}