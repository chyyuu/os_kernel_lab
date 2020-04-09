## 实现格式化输出

只能使用 `console_putchar` 这种苍白无力的输出手段让人头皮发麻。如果我们能使用 `print!` 宏的话该有多好啊！于是我们就来实现自己的 `print!`宏！

我们将这一部分放在 `src/io.rs` 中，先用 `console_putchar` 实现两个基础函数：

```rust
// src/lib.rs

// 由于使用到了宏，需要进行设置
// 同时，这个 module 还必须放在其他 module 前
#[macro_use]
mod io;

// src/io.rs

use crate::sbi;

// 输出一个字符
pub fn putchar(ch: char) {
    sbi::console_putchar(ch as u8 as usize);
}

// 输出一个字符串
pub fn puts(s: &str) {
    for ch in s.chars() {
        putchar(ch);
    }
}
```

而关于格式化输出， Rust 中提供了一个接口 `core::fmt::Write` ，你需要实现函数

```rust
// required
fn write_str(&mut self, s: &str) -> Result
```

随后你就可以调用如下函数（会进一步调用`write_str` 实现函数）来进行显示。

```rust
// provided
fn write_fmt(mut self: &mut Self, args: Arguments<'_>) -> Result
```

`write_fmt` 函数需要处理 `Arguments` 类封装的输出字符串。而我们已经有现成的 `format_args!` 宏，它可以将模式字符串+参数列表的输入转化为 `Arguments` 类！比如 `format_args!("{} {}", 1, 2)` 。

因此，我们的 `print!` 宏的实现思路便为：

1. 解析传入参数，转化为 `format_args!` 可接受的输入（事实上原封不动就行了），并通过 `format_args!` 宏得到 `Arguments` 类；
2. 调用 `write_fmt` 函数输出这个类；

而为了调用 `write_fmt` 函数，我们必须实现 `write_str` 函数，而它可用 `puts` 函数来实现。支持`print!`宏的代码片段如下：

```rust
// src/io.rs

use core::fmt::{ self, Write };

struct Stdout;

impl fmt::Write for Stdout {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        puts(s);
        Ok(())
    }
}

pub fn _print(args: fmt::Arguments) {
    Stdout.write_fmt(args).unwrap();
}

#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => ({
        $crate::io::_print(format_args!($($arg)*));
    });
}

#[macro_export]
macro_rules! println {
    () => ($crate::print!("\n"));
    ($($arg:tt)*) => ($crate::print!("{}\n", format_args!($($arg)*)));
}
```

由于并不是重点就不在这里赘述宏的语法细节了（实际上我也没弄懂），总之我们实现了 `print!, println!` 两个宏，现在是时候看看效果了！
首先，我们在 `panic` 时也可以看看到底发生了什么事情了！

```rust
// src/lang_items.rs

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    println!("{}", info);
    loop {}
}
```

其次，我们可以验证一下我们之前为内核分配的内存布局是否正确：

```rust
// src/init.rs

use crate::io;
use crate::sbi;

#[no_mangle]
pub extern "C" fn rust_main() -> ! {
    extern "C" {
        fn _start();
        fn bootstacktop();
    }
    println!("_start vaddr = 0x{:x}", _start as usize);
    println!("bootstacktop vaddr = 0x{:x}", bootstacktop as usize);
    println!("hello world!");
    panic!("you want to do nothing!");
    loop {}
}
```

`make run` 一下，我们可以看到输出为：

> **[success] 格式化输出通过**
>
> ```rust
> _start vaddr = 0x80200000
> bootstacktop vaddr = 0x80208000
> hello world!
> panicked at 'you want to do nothing!', src/init.rs:15:5
> ```

我们看到入口点的地址确实为我们安排的 `0x80200000` ，同时栈的地址也与我们在内存布局中看到的一样。更重要的是，我们现在能看到内核 `panic` 的位置了！这将大大有利于调试。

目前所有的代码可以在[这里][code]找到。