use virtio_drivers::{DeviceType, VirtIOHeader, VirtIOBlk};
use device_tree::Node;
use device_tree::util::SliceRead;
use crate::memory::{VirtualAddress, PhysicalAddress};
use spin::Mutex;
use alloc::sync::Arc;
use crate::drivers::driver::DriverResult;
use rcore_fs::dev::{self, BlockDevice, DevError};
use rcore_fs_sfs::SimpleFileSystem;

struct VirtIOBlkDriver(Mutex<VirtIOBlk<'static>>);

impl BlockDevice for VirtIOBlkDriver {
    const BLOCK_SIZE_LOG2: u8 = 9; // 512
    fn read_at(&self, block_id: usize, buf: &mut [u8]) -> dev::Result<()> {
        match self.0.lock().read_block(block_id, buf).is_ok() {
            true => Ok(()),
            false => Err(DevError),
        }
    }

    fn write_at(&self, block_id: usize, buf: &[u8]) -> dev::Result<()> {
        match self.0.lock().write_block(block_id, buf).is_ok() {
            true => Ok(()),
            false => Err(DevError),
        }
    }

    fn sync(&self) -> dev::Result<()> {
        Ok(())
    }
}

pub fn add_blk_driver(header: &'static mut VirtIOHeader) {
    let virtio_blk = VirtIOBlk::new(header).expect("failed to init blk driver");
    let driver = Arc::new(VirtIOBlkDriver(Mutex::new(virtio_blk)));
    DRIVERS.write().push(driver.clone());

    let sfs = SimpleFileSystem::open(driver);
}

pub fn virtio_probe(node: &Node) {
    let reg = match node.prop_raw("reg") {
        Some(reg) => reg,
        _ => return,
    };
    let paddr = PhysicalAddress(reg.as_slice().read_be_u64(0).unwrap() as usize);
    let vaddr = VirtualAddress::from(paddr);
    let size = reg.as_slice().read_be_u64(8).unwrap();
    // assuming one page
    assert_eq!(size as usize, 4096);
    let header = unsafe { &mut *(vaddr.0 as *mut VirtIOHeader) };
    if !header.verify() {
        // only support legacy device
        return;
    }
    println!("vendor id: {:#x}", header.vendor_id());
    println!("Device tree node {:?}", node);
    match header.device_type() {
        DeviceType::Block => add_blk_driver(header),
        t => println!("unrecognized virtio device: {:?}", t),
    }
}