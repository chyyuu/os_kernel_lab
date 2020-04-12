## 时钟中断

本章的最后，我们来实现操作系统中极其重要的时钟中断。时钟中断是操作系统能够进行线程调度的基础，操作系统会在每次时钟中断时被唤醒，暂停正在执行的线程，并根据调度算法选择下一个应当运行的线程。

> **[info] RISC-V 中断寄存器的细分**
> 
> 在[前面](part-2.md#指导硬件处理中断的寄存器)提到，`sie` 和 `sip` 寄存器分别保存不同中断种类的使能和触发记录。例如，软件中断的使能是 `sie` 中的 SSIE 位，触发记录是 `sip` 中的 SSIP 位。
> 
> RISC-V 中将中断分为三种：
> - 软件中断（Software Interrupt），对应 SSIE 和 SSIP
> - 时钟中断（Timer Interrupt），对应 STIE 和 STIP
> - 外部中断（External Interrupt），对应 SEIE 和 SEIP

### 开启时钟中断

时钟中断也需要我们在初始化操作系统时开启，我们同样只需使用 riscv 库中提供的接口即可。

{% label %}os/src/interrupt/timer.rs{% endlabel %}
```rust
pub fn init() {
    unsafe {
        // 开启 STIE，允许时钟中断
        sie::set_stimer(); 
        // 开启 SIE（不是 sie 寄存器），允许 内核态被中断打断
        sstatus::set_sie();
    }
    // 设置下一次时钟中断
    set_next_timeout();
}
```

这里可能引起误解的是 `sstatus::set_sie()`，它的作用是开启 `sstatus` 寄存器中的 SIE 位，与 `sie` 寄存器无关。SIE 位决定中断是否能够打断 supervisor 线程。在这里我们需要允许时钟中断打断 内核态线程，因此置 SIE 位为 1。  
另外，无论 SIE 位为什么值，中断都可以打断用户态的线程。

### 设置时钟中断

每一次的时钟中断都需要操作系统设置一个下一次中断的时间，硬件会在指定的时间发出时钟中断。为了便于后续处理，我们设置时钟间隔为 100000 CPU 周期。越短的间隔可以让 CPU 调度资源更加细致，但同时也会导致更多资源浪费在操作系统上。

{% label %}os/src/interrupt/timer.rs{% endlabel %}
```rust
/// 时钟中断的间隔，单位是 CPU 指令
static INTERVAL: usize = 100000;

/// 设置下一次时钟中断
fn set_next_timeout() {
    // 内核态可以访问 time 寄存器，记录了当前时间
    set_timer(time::read() + INTERVAL);
}
```

由于没有一个接口来设置固定重复的时间中断间隔，因此我们需要在每一次时钟中断时，设置再下一次的时钟中断。

{% label %}os/src/interrupt/timer.rs{% endlabel %}
```rust
/// 触发时钟中断计数
pub static mut TICKS: usize = 0;

/// 每一次时钟中断时调用
pub fn tick() {
    set_next_timeout();
    unsafe {
        TICKS += 1;
        if TICKS % 100 == 0 {
            println!("100 ticks~");
        }
    }
}
```

### 实现时钟中断的处理流程

接下来，我们在 `handle_interrupt()` 根据不同中断种类进行不同的处理流程。

{% label %}os/src/interrupt/handler.rs{% endlabel %}
```rust
#[no_mangle]
pub fn handle_interrupt(trap_frame: &mut TrapFrame) {
    match trap_frame.scause.cause() {
        // 断点中断（ebreak）
        Trap::Exception(Exception::Breakpoint) => breakpoint(trap_frame),
        // 时钟中断
        Trap::Interrupt(Interrupt::SupervisorTimer) => supervisor_timer(trap_frame),
        // 其他情况未实现
        trap => unimplemented!("{:?}", trap),
    }
}

/// 处理 ebreak 断点
fn breakpoint(trap_frame: &mut TrapFrame) {
    println!("Breakpoint at 0x{:x}", trap_frame.sepc);
    trap_frame.sepc += 2;
}

/// 处理时钟中断
fn supervisor_timer(_: &TrapFrame) {
    timer::tick();
}
```

至此，时钟中断就可以正常工作了。最后我们在 main 函数中插入 `loop {}` 防止程序退出，然后观察时钟中断。应当可以看到程序每隔一秒左右输出一次 `100 ticks~`