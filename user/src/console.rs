use alloc::collections::vec_deque::VecDeque;
use alloc::sync::Arc;
use core::fmt::{self, Write};
use spin::mutex::Mutex;

pub const STDIN: usize = 0;
pub const STDOUT: usize = 1;

const CONSOLE_BUFFER_SIZE: usize = 256 * 10;

use super::{read, write};
use lazy_static::*;

struct ConsoleBuffer(VecDeque<u8>);

lazy_static! {
    static ref CONSOLE_BUFFER: Arc<Mutex<ConsoleBuffer>> = {
        let buffer = VecDeque::<u8>::with_capacity(CONSOLE_BUFFER_SIZE);
        Arc::new(Mutex::new(ConsoleBuffer(buffer)))
    };
}

impl ConsoleBuffer {
    fn flush(&mut self) -> isize {
        let s: &[u8] = self.0.make_contiguous();
        let ret = write(STDOUT, s);
        self.0.clear();
        ret
    }
}

impl Write for ConsoleBuffer {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for c in s.as_bytes().iter() {
            self.0.push_back(*c);
            if (*c == b'\n' || self.0.len() == CONSOLE_BUFFER_SIZE) && -1 == self.flush() {
                return Err(fmt::Error);
            }
        }
        Ok(())
    }
}

#[allow(unused)]
pub fn print(args: fmt::Arguments) {
    let mut buf = CONSOLE_BUFFER.lock();
    // buf.write_fmt(args).unwrap();
    // BUG FIX: 关闭 stdout 后，本函数不能触发 panic，否则会造成死锁
    buf.write_fmt(args);
}

#[macro_export]
macro_rules! print {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        $crate::console::print(format_args!($fmt $(, $($arg)+)?));
    }
}

#[macro_export]
macro_rules! println {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        $crate::console::print(format_args!(concat!($fmt, "\n") $(, $($arg)+)?));
    }
}

pub fn getchar() -> u8 {
    let mut c = [0u8; 1];
    read(STDIN, &mut c);
    c[0]
}

pub fn flush() {
    let mut buf = CONSOLE_BUFFER.lock();
    buf.flush();
}
