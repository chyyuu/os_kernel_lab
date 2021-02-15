extern crate alloc;

use std::fs::{read_dir, File, OpenOptions};
use std::io::{Read, Seek, SeekFrom, Write};
use std::sync::Mutex;
use efs::{BlockDevice,SuperBlock, EasyFileSystem,BLOCK_SZ};
use alloc::sync::Arc;

//------------faked block device---------------------------------

struct BlockFile(Mutex<File>);

impl BlockDevice for BlockFile {
    fn read_block(&self, block_id: usize, buf: &mut [u8]) {
        let mut file = &mut self.0.lock().unwrap();
        file.seek(SeekFrom::Start((block_id * BLOCK_SZ) as u64))
            .expect("Error when seeking!");
        assert_eq!(file.read(buf).unwrap(), BLOCK_SZ, "Not a complete block!");
    }

    fn write_block(&self, block_id: usize, buf: &[u8]) {
        let mut file = &mut self.0.lock().unwrap();
        file.seek(SeekFrom::Start((block_id * BLOCK_SZ) as u64))
            .expect("Error when seeking!");
        assert_eq!(file.write(buf).unwrap(), BLOCK_SZ, "Not a complete block!");
    }
}


//---------------------------test -------------------------------------
fn efs_test()->std::io::Result<()>{
    let mut blk= Arc::new(BlockFile(Mutex::new({
        //create block file efs.img
        let f=OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .open("./efs.img")?;
        //4MB block file
        f.set_len(8192 * 512).unwrap();
        f
    })));

    let mut rb=[b'b';512];
    let wb=[b'a';512];
    assert_ne!(rb,wb);
    blk.write_block(0, &wb);
    blk.read_block(0,&mut rb);
    assert_eq!(rb,wb);
    println!("test block device file write/read OK!");

    // 4MiB, at most 4095 files
    let efs = EasyFileSystem::create(blk.clone(), 8192, 1);
    let root_inode = Arc::new(EasyFileSystem::root_inode(&efs));
    println!("create efs img OK!");
    let apps: Vec<(String, String)> = read_dir("./mytest")
        .unwrap()
        .into_iter()
        .map(|dir_entry| {
            let mut name_with_ext = dir_entry.unwrap().file_name().into_string().unwrap();
            //name_with_ext.drain(name_with_ext.find('.').unwrap()..name_with_ext.len());
            let name_with_dir=format!("{}{}", "./mytest/",name_with_ext);
            (name_with_dir,name_with_ext)
        })
        .collect();
    for app in apps {
        // load app data from host file systemname_with_ext
        let mut host_file = File::open(&app.0).unwrap();
        let mut all_data: Vec<u8> = Vec::new();
        host_file.read_to_end(&mut all_data).unwrap();
        // create a file in easy-fs
        let inode = root_inode.create(&app.1).unwrap();
        // write data to easy-fs
        inode.write_at(0, all_data.as_slice());
    }
    // list apps
    for app in root_inode.ls() {
        println!("{}", app);
    }

    println!("write files in efs OK!");
    //--------------------------------
    let efs = EasyFileSystem::open(blk.clone());
    let mut root_inode = EasyFileSystem::root_inode(&efs);
    let filea = root_inode.find("hello.txt").unwrap();
    let mut buffer = [0u8; 512];
    let len = filea.read_at(0, &mut buffer);
    let greet_str = "Hello\n";
    assert_eq!(
        greet_str,
        core::str::from_utf8(&buffer[..len]).unwrap(),
    );
    println!("read files in efs OK!");
    Ok(())
}
fn main() {
    println!("Hello, world!");
    efs_test();
}
