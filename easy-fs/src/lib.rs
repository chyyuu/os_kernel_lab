extern crate alloc;

mod block_dev;
mod layout;
mod efs;
mod dirty;
mod bitmap;
mod vfs;

pub const BLOCK_SZ: usize = 512;
pub use block_dev::BlockDevice;
pub use efs::EasyFileSystem;
pub use vfs::Inode;
use layout::*;
use dirty::Dirty;
use bitmap::Bitmap;