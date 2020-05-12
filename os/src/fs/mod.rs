use lazy_static::lazy_static;
use rcore_fs::vfs::*;
use rcore_fs_sfs::SimpleFileSystem;
use crate::drivers::driver::{DRIVERS, DeviceType, BlockDriver};
use alloc::sync::Arc;
use rcore_fs::dev::block_cache::BlockCache;

lazy_static! {
    pub static ref ROOT_INODE: Arc<dyn INode> = {
        for driver in DRIVERS.read().iter() {
            if driver.device_type() == DeviceType::Block {
                let driver = BlockDriver(driver.clone());
                let device = Arc::new(BlockCache::new(driver, 0x100));
                return SimpleFileSystem::open(device).expect("failed to open SFS").root_inode();
            }
        }
        panic!("failed to load fs")
    };
}

pub fn init() {
    let mut id = 0;
    let dir = ROOT_INODE.lookup("rust").unwrap();
    while let Ok(name) = dir.get_entry(id) {
        id += 1;
        println!("{}", name);
    }
    println!("mod fs initialized");
}