mod virtio_blk;


pub trait BlockDevice {
    fn read_block(&mut self, block_id: usize, buf: &mut [u8]);
    fn write_block(&mut self, block_id: usize, buf: &[u8]);
}

type BlockDeviceImpl = virtio_blk::VirtIOBlock;

pub fn block_device_test() {
    let mut block_device = BlockDeviceImpl::new();
    let mut write_buffer = [0u8; 512];
    let mut read_buffer =  [0u8; 512];
    for i in 0..512 {
        for byte in write_buffer.iter_mut() { *byte = i as u8; }
    }
    block_device.write_block(0 as usize, &write_buffer);
    block_device.read_block(0 as usize, &mut read_buffer);
    assert_eq!(write_buffer, read_buffer);

    println!("block device test passed!");
}