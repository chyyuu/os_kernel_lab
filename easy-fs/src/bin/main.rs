extern crate easy_fs;
extern crate alloc;

use easy_fs::{
    BlockDevice,
    EasyFileSystem,
};
use std::fs::{File, OpenOptions};
use std::io::{Read, Write, Seek, SeekFrom};
use std::sync::Mutex;
use alloc::sync::Arc;

const BLOCK_SZ: usize = 512;

struct BlockFile(Mutex<File>);

impl BlockDevice for BlockFile {
    fn read_block(&self, block_id: usize, buf: &mut [u8]) {
        let mut file = self.0.lock().unwrap();
        file.seek(SeekFrom::Start((block_id * BLOCK_SZ) as u64))
            .expect("Error when seeking!");
        assert_eq!(file.read(buf).unwrap(), BLOCK_SZ, "Not a complete block!");
    }

    fn write_block(&self, block_id: usize, buf: &[u8]) {
        let mut file = self.0.lock().unwrap();
        file.seek(SeekFrom::Start((block_id * BLOCK_SZ) as u64))
            .expect("Error when seeking!");
        assert_eq!(file.write(buf).unwrap(), BLOCK_SZ, "Not a complete block!");
    }
}

fn main() {
    easy_fs_pack().expect("Error when packing easy-fs!");
}

fn easy_fs_pack() -> std::io::Result<()> {
    let block_file = BlockFile(Mutex::new(
        OpenOptions::new()
            .read(true)
            .write(true)
            .open("target/fs.img")?
    ));
    /*
    let _efs = EasyFileSystem::create(
        Arc::new(block_file),
        4096,
        1,
    );
     */
    let _efs = EasyFileSystem::open(Arc::new(block_file));
    Ok(())
}