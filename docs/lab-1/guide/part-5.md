## 进入中断处理流程

接下来，我们将要手动触发一个 Trap（`ebreak`），并且进入中断处理流程。

### 开启中断

为了让硬件能够找到我们编写的 `__interrupt` 入口，在操作系统初始化时，需要将其写入 `stvec` 寄存器中：

{% label %}os/src/interrupt/handler.rs{% endlabel %}
```rust
use super::context::Context;
use riscv::register::stvec;

global_asm!(include_str!("../asm/interrupt.asm"));

/// 初始化中断处理
///
/// 把中断入口 `__interrupt` 写入 `stvec` 中，并且开启中断使能
pub fn init() {
    unsafe {
        extern "C" {
            /// `interrupt.asm` 中的中断入口
            fn __interrupt();
        }
        // 使用 Direct 模式，将中断入口设置为 `__interrupt`
        stvec::write(__interrupt as usize, stvec::TrapMode::Direct);
    }
}
```

### 处理中断

然后，我们再补上 `__interrupt` 后跳转的中断处理流程 `handle_interrupt()`：

{% label %}os/src/interrupt/handler.rs{% endlabel %}
```rust
/// 中断的处理入口
/// 
/// `interrupt.asm` 首先保存寄存器至 Context，其作为参数和 scause 以及 stval 一并传入此函数
/// 具体的中断类型需要根据 scause 来推断，然后分别处理
#[no_mangle]
pub fn handle_interrupt(context: &mut Context, scause: Scause, stval: usize) {
    panic!("Interrupted: {:?}", scause.cause());
}
```

### 触发中断

最后，我们把刚刚写的函数封装一下：

{% label %}os/src/interrupt/mod.rs{% endlabel %}
```rust
//! 中断模块
//! 
//! 

mod handler;
mod context;

/// 初始化中断相关的子模块
/// 
/// - [`handler::init`]
/// - [`timer::init`]
pub fn init() {
    handler::init();
    println!("mod interrupt initialized");
}
```

同时，我们在 main 函数中主动使用 `ebreak` 来触发一个中断。

{% label %}os/src/main.rs{% endlabel %}
```rust
...
mod interrupt;
...

/// Rust 的入口函数
///
/// 在 `_start` 为我们进行了一系列准备之后，这是第一个被调用的 Rust 函数
pub extern "C" fn rust_main() -> ! {
    // 初始化各种模块
    interrupt::init();

    unsafe {
        llvm_asm!("ebreak"::::"volatile");
    };

    unreachable!();
}
```

运行一下，可以看到 `ebreak` 导致程序进入了中断处理并退出，而没有执行到后面的 `unreachable!()`：

{% label %}运行输出{% endlabel %}
```
Hello rCore-Tutorial!
mod interrupt initialized
panic: 'Interrupted: Exception(Breakpoint)'
```