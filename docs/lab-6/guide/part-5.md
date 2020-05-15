## 处理文件描述符

尽管很不像，但是在大多操作系统中，标准输入输出流 `stdin` 和 `stdout` 虽然叫做『流』，但它们都有文件的接口。我们同样也会将它们实现成为文件。

但是不用担心，作为文件的许多功能，`stdin` 和 `stdout` 都不会支持。我们只需要为其实现最简单的读写接口。

### 进程打开的文件

为每一个进程，我们需要维护一个其打开的文件的清单。其中，一定存在的是 `stdin` `stdout` 和 `stderr`。为了简便，我们只实现 `stdin` 和 `stdout`，它们的文件描述符数值分别为 0 和 1。

### `stdout`

输出流最为简单：每当遇到系统调用时，直接将缓冲区中的字符再通过 SBI 调用打印出去。

### `stdin`

#### 外部中断

对于用户程序而言，外部输入是随时主动读取的数据。但是事实上外部输入通常时间短暂且不会等待，需要操作系统立即处理并缓冲下来，再等待程序进行读取。所以，每一个键盘按键对于操作系统而言都是一次短暂的中断。

而之所以我们在之前的实验中，操作系统不会因为一个按键就崩溃，是因为 OpenSBI 默认会关闭各种外部中断。但是现在我们需要将其打开，来接受按键信息。

{% label %}os/src/interrupt/handler.rs{% endlabel %}
```rust
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

        // 开启外部中断使能
        sie::set_sext();

        // 在 OpenSBI 中开启外部中断
        *PhysicalAddress(0x0c00_2080).deref_kernel() = 1 << 10;
        // 在 OpenSBI 中开启串口
        *PhysicalAddress(0x1000_0004).deref_kernel() = 0x0bu8;
        *PhysicalAddress(0x1000_0001).deref_kernel() = 0x01u8;
    }
}
```

这里，我们需要按照 OpenSBI 的接口在指定的地址进行配置。好在这些地址都在文件系统映射的空间内，就不需要再为其单独建立内存映射了。开启中断使能后，任何一个按键都会导致程序进入 `unimplemented!` 的区域。

#### 实现输入流

输入流则需要配有一个缓冲区，我们可以用 `alloc::collections::VecDeque` 来实现。在遇到键盘中断时，调用 `sbi_call` 来获取字符并加入到缓冲区中。当遇到系统调用 `sys_read` 时，再相应从缓冲区中取出一定数量的字符。

那么，如果遇到了 `sys_read` 系统调用，而缓冲区并没有数据可以读取，应该如何让线程进行等待，而又不浪费 CPU 资源呢？
