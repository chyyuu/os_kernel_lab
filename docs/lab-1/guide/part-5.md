## 进入中断处理流程

接下来，我们将要手动触发一个 Trap（`ebreak`），并且进入中断处理流程。

### 开启中断

为了让硬件能够找到我们编写的 `__interrupt` 入口，在操作系统初始化时，需要将其写入 `stvec` 寄存器中

{% label %}os/src/interrupt/handler.rs{% endlabel %}
```rust
global_asm!(include_str!("../asm/interrupt.asm"));

pub fn init() {
    unsafe {
        extern "C" {
            /// `asm/interrupt.asm` 中的中断入口
            fn __interrupt();
        }
        // 使用 Direct 模式，将中断入口设置为 `__interrupt`
        stvec::write(__interrupt as usize, stvec::TrapMode::Direct);
    }
}
```

### 处理中断

然后，我们再补上 `__interrupt` 后跳转的中断处理流程 `handle_interrupt()`

{% label %}os/src/interrupt/handler.rs{% endlabel %}
```rust
#[no_mangle]
pub fn handle_interrupt(trap_frame: &mut TrapFrame) {
    panic!("Interrupted: {:?}", trap_frame.scause.cause());
}
```

### 触发中断

最后，我们在 main 函数中主动使用 `ebreak` 来触发一个中断。

{% label %}os/src/main.rs{% endlabel %}
```rust
pub extern "C" fn rust_main() -> ! {
    interrupt::init();
    unsafe { asm!("ebreak"::::"volatile"); }
    unreachable!();
}
```

运行一下，可以看到 `ebreak` 导致程序进入了中断处理并退出，而没有执行到后面的 `unreachable!()`

{% label %}运行输出{% endlabel %}
```
Hello rCore-Tutorial!
mod interrupt initialized
panic: 'Interrupted: Exception(Breakpoint)'
```

### 代码

至此的代码可以在这里找到 TODO