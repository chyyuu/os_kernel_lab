//! 文件系统
//!
//! 将读取第一个块设备作为根文件系统

use crate::drivers::{
    block::BlockDevice,
    driver::{DeviceType, DRIVERS},
};
use alloc::sync::Arc;
use config::*;
use lazy_static::lazy_static;
use rcore_fs::{dev::block_cache::BlockCache, vfs::*};
use rcore_fs_sfs::SimpleFileSystem;

pub mod config;

lazy_static! {
    /// 根文件系统的根目录的 INode
    pub static ref ROOT_INODE: Arc<dyn INode> = {
        // 选择第一个块设备
        for driver in DRIVERS.read().iter() {
            if driver.device_type() == DeviceType::Block {
                let device = BlockDevice(driver.clone());
                // 动态分配一段内存空间作为设备 Cache
                let device_with_cache = Arc::new(BlockCache::new(device, BLOCK_CACHE_CAPACITY));
                return SimpleFileSystem::open(device_with_cache)
                    .expect("failed to open SFS")
                    .root_inode();
            }
        }
        panic!("failed to load fs")
    };
}

/// 打印某个目录的全部文件
pub fn ls(path: &str) {
    let mut id = 0;
    let dir = ROOT_INODE.lookup(path).unwrap();
    print!("files in {}: \n  ", path);
    while let Ok(name) = dir.get_entry(id) {
        id += 1;
        print!("{} ", name);
    }
    print!("\n");
}

/// 触发 [`static@ROOT_INODE`] 的初始化并打印根目录内容
pub fn init() {
    ls("/");
    println!("mod fs initialized");
}
