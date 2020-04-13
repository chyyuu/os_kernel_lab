## 程序运行状态

对于用户程序而言，中断的处理应当是不留任何痕迹的：只要中断处理改动了一个寄存器，都可能导致原本正在运行的线程出现错误。因此，在处理中断之前，必须要保存所有可能被修改的寄存器，并且在处理完成后恢复。因此，我们需要保存所有通用寄存器，`sepc`、`scause` 和 `stval` 这三个会被硬件自动写入的 CSR 寄存器，以及 `sstatus`。因为中断可能会涉及到权限的切换，以及中断的开关，这些都会修改 `sstatus`。

### TrapFrame

我们把在中断时保存了各种寄存器的组构体叫做 `TrapFrame`，其定义如下：

{% label %}os/src/interrupt/trap_frame.rs{% endlabel %}
```rust
use riscv::register::{sstatus::Sstatus, scause::Scause};

#[repr(C)]
pub struct TrapFrame {
    pub x: [usize; 32],     // 32 个通用寄存器
    pub sstatus: Sstatus,
    pub sepc: usize,
    pub scause: Scause,
    pub stval: usize,
}
```

这里我们使用了 rCore 中的库 riscv 封装的一些寄存器操作，需要在 `os/Cargo.toml` 中添加依赖。

{% label %}os/Cargo.toml{% endlabel %}
```toml
[dependencies]
riscv = { git = "https://github.com/rcore-os/riscv", features = ["inline-asm"] }
```