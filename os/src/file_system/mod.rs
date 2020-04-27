//! 文件系统
//! 
//! 使用一段内存空间进行模拟，操作系统启动时会首先将文件系统镜像加载到这段空间中。

mod swap_file;

pub use crate::memory::*;
pub use swap_file::SWAP_FILE;