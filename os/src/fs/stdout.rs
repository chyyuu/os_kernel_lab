//! 控制台输出 [`Stdout`]

use super::*;

lazy_static!{
    pub static ref STDOUT: Arc<Stdout> = Default::default();
}

/// 控制台输出
#[derive(Default)]
pub struct Stdout;

impl INode for Stdout {
    fn write_at(&self, offset: usize, buf: &[u8]) -> Result<usize> {
        if offset != 0 {
            Err(FsError::NotSupported)
        } else if let Ok(string) = core::str::from_utf8(buf) {
            print!("{}", string);
            Ok(buf.len())
        } else {
            Err(FsError::InvalidParam)
        }
    }

    /// Read bytes at `offset` into `buf`, return the number of bytes read.
    fn read_at(&self, _offset: usize, _buf: &mut [u8]) -> Result<usize> {
        Err(FsError::NotSupported)
    }

    fn poll(&self) -> Result<PollStatus> {
        Err(FsError::NotSupported)
    }

    /// This is used to implement dynamics cast.
    /// Simply return self in the implement of the function.
    fn as_any_ref(&self) -> &dyn Any {
        self
    }
}
