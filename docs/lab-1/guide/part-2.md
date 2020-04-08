## 移除标准库依赖

### 禁用标准库
项目默认是链接 Rust 标准库 std 的，它依赖于操作系统，因此我们需要显式将其禁用：

```rust
// os/src/main.rs

//! # 全局属性
//! - `#![no_std]`  
//!   禁用标准库
#![no_std]

fn main() {
    println!("Hello, world!");
}
```

我们使用 `cargo build` 构建项目，会出现下面的错误：

> **[danger] Build Error**
>
> ```rust
> error: cannot find macro `println` in this scope
>  --> src/main.rs:3:5
>   |
> 7 |     println!("Hello, world!");
>   |     ^^^^^^^
> error: `#[panic_handler]` function required, but not found
> error: language item required, but not found: `eh_personality`
> ```

接下来，我们依次解决这些问题。

### 宏 println!

第一个错误是说 `println!` 宏未找到，实际上这个宏属于 Rust 标准库 std，由于它被我们禁用了当然就找不到了。我们暂时将该输出语句删除，之后给出不依赖操作系统的实现。

> **[info] `println!` 哪里依赖了操作系统**
>
> 这个宏所调用的函数会输出到标准输出，而这需要操作系统的支持。

### panic 处理函数

第二个错误是说需要一个函数作为 `panic_handler` ，这个函数负责在程序 `panic` 时调用。它默认使用标准库 std 中实现的函数并依赖于操作系统特殊的文件描述符，由于我们禁用了标准库，因此只能自己实现它：

```rust
// os/src/main.rs

use core::panic::PanicInfo;

/// 当 panic 发生时会调用该函数
/// 我们暂时将他的实现为一个死循环
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
```

> **[info] Rust Panic**
>
> panic 在 Rust 中表明程序遇到了不可恢复的错误，只能被迫停止运行。

类型为 PanicInfo 的参数包含了 panic 发生的文件名、代码行数和可选的错误信息。这个函数从不返回，所以他被标记为发散函数（diverging function）。发散函数的返回类型称作 Never 类型（"never" type），记为 `!`。对这个函数，我们目前能做的很少，所以我们只需编写一个死循环 `loop {}`。

这里我们用到了核心库 `core` ，与标准库 `std` 不同，这个库不需要操作系统的支持，下面我们还会与它打交道。

### eh_personality 语义项

第三个错误提到了语义项（language item） ，它是编译器内部所需的特殊函数或类型。刚才的 `panic_handler` 也是一个语义项，我们要用它告诉编译器当程序 panic 之后如何处理。

而这个错误相关语义项 `eh_personality` ，其中 "eh" 是 "exception handling" 的缩写，它是一个标记某函数用来实现 **堆栈展开** 处理功能的语义项。这个语义项也与 `panic` 有关。

> **[info] 堆栈展开 (stack unwinding) **
>
> 通常，当程序出现了异常 (这里指类似 Java 中层层抛出的异常)，从异常点开始会沿着 caller 调用栈一层一层回溯，直到找到某个函数能够捕获 (catch) 这个异常。这个过程称为堆栈展开。
>
> 当程序出现不可恢复错误时，我们需要沿着调用栈一层层回溯上去回收每个 caller 中定义的局部变量避免造成内存溢出。这里的回收包括 C++ 的 RAII 的析构以及 Rust 的 drop。
>
> 而在 Rust 中，panic 证明程序出现了不可恢复错误，我们则会对于每个 caller 函数调用依次这个被标记为堆栈展开处理函数的函数。
>
> 这个处理函数是一个依赖于操作系统的复杂过程，在标准库中实现，我们禁用了标准库使得编译器找不到该过程的实现函数了。

简单起见，我们暂时不考虑内存溢出，设置当程序 panic 时不做任何清理工作，直接退出程序即可。这样堆栈展开处理函数不会被调用，编译器也就不会去寻找它的实现了。

因此，我们在项目配置文件中直接将 dev 配置 (对应构建命令为 `cargo build`) 和 release 配置（对应构建命令为 `cargo build --release`）的 panic 的处理策略设为 abort。

```rust
// Cargo.toml
...

# panic 时直接终止，因为我们没有实现堆栈展开的功能
[profile.dev]
panic = "abort"

[profile.release]
panic = "abort"
```

此时，我们 `cargo build` ，但是又出现了新的错误，我们将在后面的部分解决：

> **[danger] Build Error**
>
> `` error: requires `start` lang_item ``