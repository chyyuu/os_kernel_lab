//! 在系统调用基础上实现 `print!` `println!`
//!
//! 代码与 `os` crate 中的 `console.rs` 基本相同

use crate::syscall::*;
use core::fmt::{self, Write};

/// 实现 [`core::fmt::Write`] trait 来进行格式化输出
struct Stdout;

impl Write for Stdout {
    /// 打印一个字符串
    fn write_str(&mut self, s: &str) -> fmt::Result {
        let mut buffer = [0u8; 4];
        for c in s.chars() {
            for code_point in c.encode_utf8(&mut buffer).as_bytes().iter() {
                sys_write(*code_point as usize);
            }
        }
        Ok(())
    }
}

/// 打印由 [`core::format_args!`] 格式化后的数据
pub fn print(args: fmt::Arguments) {
    Stdout.write_fmt(args).unwrap();
}

/// 实现类似于标准库中的 `print!` 宏
#[macro_export]
macro_rules! print {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        $crate::console::print(format_args!($fmt $(, $($arg)+)?));
    }
}

/// 实现类似于标准库中的 `println!` 宏
#[macro_export]
macro_rules! println {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        $crate::console::print(format_args!(concat!($fmt, "\n") $(, $($arg)+)?));
    }
}
