use alloc::sync::Arc;
use alloc::vec::Vec;

use lazy_static::lazy_static;
use rcore_fs::dev::{self, BlockDevice};
use spin::RwLock;

#[derive(Debug, Eq, PartialEq)]
pub enum DeviceType {
    Block,
}

pub trait Driver: Send + Sync {
    fn device_type(&self) -> DeviceType;

    fn read_block(&self, _block_id: usize, _buf: &mut [u8]) -> bool {
        unimplemented!("not a block driver")
    }

    fn write_block(&self, _block_id: usize, _buf: &[u8]) -> bool {
        unimplemented!("not a block driver")
    }
}

lazy_static! {
    pub static ref DRIVERS: RwLock<Vec<Arc<dyn Driver>>> = RwLock::new(Vec::new());
}

pub struct BlockDriver(pub Arc<dyn Driver>);

impl BlockDevice for BlockDriver {
    const BLOCK_SIZE_LOG2: u8 = 9;

    fn read_at(&self, block_id: usize, buf: &mut [u8]) -> dev::Result<()> {
        match self.0.read_block(block_id, buf) {
            true => Ok(()),
            false => Err(dev::DevError),
        }
    }

    fn write_at(&self, block_id: usize, buf: &[u8]) -> dev::Result<()> {
        match self.0.write_block(block_id, buf) {
            true => Ok(()),
            false => Err(dev::DevError),
        }
    }

    fn sync(&self) -> dev::Result<()> {
        Ok(())
    }
}
