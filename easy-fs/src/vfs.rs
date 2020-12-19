use super::{
    BlockDevice,
    Dirty,
    DiskInode,
    DiskInodeType,
    DirEntry,
    DirentBytes,
    EasyFileSystem,
    DIRENT_SZ,
};
use alloc::sync::Arc;
use alloc::string::String;
use alloc::vec::Vec;
use spin::{Mutex, MutexGuard};

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
            if DirEntry::from_bytes(&dirent_space).name() == name {
                return Some(i as u32);
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
        println!("blocks_num_needed = {}", blocks_needed);
        let mut v: Vec<u32> = Vec::new();
        for _ in 0..blocks_needed {
            v.push(fs.alloc_data());
        }
        inode.modify(|inode| {
            inode.increase_size(new_size, v, &self.block_device);
        });
    }

    pub fn create(&mut self, name: &str) -> Option<Arc<Inode>> {
        let mut fs = self.fs.lock();
        println!("creating name {}", name);
        let mut inode = self.get_disk_inode(&mut fs);
        // assert it is a directory
        assert!(inode.read(|inode| inode.is_dir()));
        // has the file been created?
        if let Some(_) = self.find_inode_id(name, &inode) {
            return None;
        }
        println!("stop1");

        // create a new file
        // alloc a inode with an indirect block
        let new_inode_id = fs.alloc_inode();
        let indirect1 = fs.alloc_data();
        println!("creating new file, new_inode_id={}, indirect={}", new_inode_id, indirect1);
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
        println!("expected new_size={}", new_size);
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
        println!("into ls!");
        let mut fs = self.fs.lock();
        let inode = self.get_disk_inode(&mut fs);
        let file_count = inode.read(|inode| {
            (inode.size as usize) / DIRENT_SZ
        });
        println!("file_count = {}", file_count);
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

    pub fn write_at(&self, offset: usize, buf: &mut [u8]) -> usize {
        let mut fs = self.fs.lock();
        let mut inode = self.get_disk_inode(&mut fs);
        self.increase_size((offset + buf.len()) as u32, &mut inode, &mut fs);
        inode.modify(|disk_inode| {
            disk_inode.write_at(offset, buf, &self.block_device)
        })
    }
}
