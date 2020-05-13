//! 块设备驱动
//!
//! 目前仅仅实现了 virtio 协议的块设备，另外还有类似 AHCI 等协议

use super::driver::Driver;
use alloc::sync::Arc;
use rcore_fs::dev::{self, BlockDevice};

pub mod virtio_blk;

/// 块设备驱动接口
pub struct BlockDriver(pub Arc<dyn Driver>);

/// 为 [`BlockDriver`] 实现 [`rcore-fs`] 中 [`BlockDevice`] trait
///
/// 使得文件系统可以通过调用块设备的该接口来读写
impl BlockDevice for BlockDriver {
    /// 每个块的大小（取 2 的对数）
    ///
    /// 这里取 512B 是因为 virtio 驱动对设备的操作粒度为 512B
    const BLOCK_SIZE_LOG2: u8 = 9;

    /// 读取某个块到 buf 中
    fn read_at(&self, block_id: usize, buf: &mut [u8]) -> dev::Result<()> {
        match self.0.read_block(block_id, buf) {
            true => Ok(()),
            false => Err(dev::DevError),
        }
    }

    /// 将 buf 中的数据写入块中
    fn write_at(&self, block_id: usize, buf: &[u8]) -> dev::Result<()> {
        match self.0.write_block(block_id, buf) {
            true => Ok(()),
            false => Err(dev::DevError),
        }
    }

    /// 执行和设备的同步
    ///
    /// 因为我们这里全部为阻塞 I/O 所以不存在同步的问题
    fn sync(&self) -> dev::Result<()> {
        Ok(())
    }
}
