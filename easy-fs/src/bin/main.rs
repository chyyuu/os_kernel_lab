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
        println!("reading block {}", block_id);
        let mut file = self.0.lock().unwrap();
        file.seek(SeekFrom::Start((block_id * BLOCK_SZ) as u64))
            .expect("Error when seeking!");
        assert_eq!(file.read(buf).unwrap(), BLOCK_SZ, "Not a complete block!");
    }

    fn write_block(&self, block_id: usize, buf: &[u8]) {
        println!("writing block {}", block_id);
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
    let block_file = Arc::new(BlockFile(Mutex::new(
        OpenOptions::new()
            .read(true)
            .write(true)
            .open("target/fs.img")?
    )));
    EasyFileSystem::create(
        block_file.clone(),
        4096,
        1,
    );
    let efs = EasyFileSystem::open(block_file.clone());
    let mut root_inode = EasyFileSystem::root_inode(&efs);
    root_inode.create("filea");
    root_inode.create("fileb");
    for name in root_inode.ls() {
        println!("{}", name);
    }
    {
        let filea = root_inode.find("filea").unwrap();
        println!("writing filea!");
        filea.write_at(0, "Hello, world!".as_bytes());
    }
    {
        let filea = root_inode.find("filea").unwrap();
        let mut buffer = [0u8; 512];
        let len = filea.read_at(0, &mut buffer);
        println!("{}", core::str::from_utf8(&buffer[..len]).unwrap());
    }
    Ok(())
}