use std::fs::{read_dir, File, OpenOptions};
use std::io::{Read, Seek, SeekFrom, Write};
use std::sync::Mutex;
use efs::{BlockDevice};

const BLOCK_SZ: usize = 512;

struct BlockFile(File);

impl BlockDevice for BlockFile {
    fn read_block(&self, block_id: usize, buf: &mut [u8]) {
        let mut file = &self.0;
        file.seek(SeekFrom::Start((block_id * BLOCK_SZ) as u64))
            .expect("Error when seeking!");
        assert_eq!(file.read(buf).unwrap(), BLOCK_SZ, "Not a complete block!");
    }

    fn write_block(&self, block_id: usize, buf: &[u8]) {
        let mut file = &self.0;
        file.seek(SeekFrom::Start((block_id * BLOCK_SZ) as u64))
            .expect("Error when seeking!");
        assert_eq!(file.write(buf).unwrap(), BLOCK_SZ, "Not a complete block!");
    }
}

fn efs_test()->std::io::Result<()>{
    let blkfs=BlockFile({
        //create block file efs.img
        let f=OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .open("./efs.img")?;
        //4MB block file
        f.set_len(8192 * 512).unwrap();
        f
    });
    Ok(())
}
fn main() {
    println!("Hello, world!");
    efs_test();
}
