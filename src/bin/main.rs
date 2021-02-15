use std::fs::{read_dir, File, OpenOptions};
use std::io::{Read, Seek, SeekFrom, Write};
use std::sync::Mutex;
use efs::{BlockDevice,SuperBlock, EasyFileSystem,BLOCK_SZ};


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
    let mut blk=BlockFile(Mutex::new({
        //create block file efs.img
        let f=OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .open("./efs.img")?;
        //4MB block file
        f.set_len(8192 * 512).unwrap();
        f
    }));

    let mut rb=[b'b';512];
    let wb=[b'a';512];
    assert_ne!(rb,wb);
    blk.write_block(0, &wb);
    blk.read_block(0,&mut rb);
    assert_eq!(rb,wb);
    println!("test block device file write/read OK!");

    // let blkfs=::new(&mut blk);
    //let efs = EasyFileSystem::create(blkfs, 8192, 1);
    Ok(())
}
fn main() {
    println!("Hello, world!");
    efs_test();
}
