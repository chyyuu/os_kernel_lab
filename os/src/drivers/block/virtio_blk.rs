use super::super::driver::{DeviceType, Driver, DRIVERS};
use alloc::sync::Arc;
use spin::Mutex;
use virtio_drivers::{VirtIOBlk, VirtIOHeader};

struct VirtIOBlkDriver(Mutex<VirtIOBlk<'static>>);

impl Driver for VirtIOBlkDriver {
    fn device_type(&self) -> DeviceType {
        DeviceType::Block
    }

    fn read_block(&self, block_id: usize, buf: &mut [u8]) -> bool {
        self.0.lock().read_block(block_id, buf).is_ok()
    }

    fn write_block(&self, block_id: usize, buf: &[u8]) -> bool {
        self.0.lock().write_block(block_id, buf).is_ok()
    }
}

pub fn add_driver(header: &'static mut VirtIOHeader) {
    let virtio_blk = VirtIOBlk::new(header).expect("failed to init blk driver");
    let driver = Arc::new(VirtIOBlkDriver(Mutex::new(virtio_blk)));
    DRIVERS.write().push(driver.clone());
}
