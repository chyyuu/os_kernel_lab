//! 键盘输入 [`Stdin`]

use super::*;
use alloc::collections::VecDeque;

lazy_static! {
    pub static ref STDIN: Arc<Stdin> = Default::default();
}

/// 控制台键盘输入，实现 [`INode`] 接口
#[derive(Default)]
pub struct Stdin {
    /// 从后插入，前段弹出
    buffer: Mutex<VecDeque<u8>>,
    /// 条件变量用于使等待输入的线程休眠
    condvar: Condvar,
}

impl INode for Stdin {
    /// Read bytes at `offset` into `buf`, return the number of bytes read.
    fn read_at(&self, offset: usize, buf: &mut [u8]) -> Result<usize> {
        if offset != 0 {
            // 不支持 offset
            Err(FsError::NotSupported)
        } else if self.buffer.lock().len() == 0 {
            // 缓冲区没有数据，将当前线程休眠
            self.condvar.wait();
            Ok(0)
        } else {
            let mut stdin_buffer = self.buffer.lock();
            for (i, byte) in buf.iter_mut().enumerate() {
                if let Some(b) = stdin_buffer.pop_front() {
                    *byte = b;
                } else {
                    return Ok(i);
                }
            }
            Ok(buf.len())
        }
    }

    /// Write bytes at `offset` from `buf`, return the number of bytes written.
    fn write_at(&self, _offset: usize, _buf: &[u8]) -> Result<usize> {
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

impl Stdin {
    /// 向缓冲区插入一个字符，然后唤起一个线程
    pub fn push(&self, c: u8) {
        self.buffer.lock().push_back(c);
        self.condvar.notify_one();
    }
}
