# 线程的切换

回答一下前一节的思考题：当发生中断时，在 `__restore` 时，`a0` 寄存器的值是 `handle_interrupt` 的返回值。也就是说，如果我们令 `handle_interrupt` 返回另一个线程的 `*mut Context`，就可以在时钟中断后跳转到这个线程来执行。

<br/>

## 修改中断处理

在线程切换时（即时钟中断时），`handle_interrupt` 需要将上一个线程的 `Context` 保存起来，然后将下一个线程的 `Context` 并返回。

> 注 1：为什么不直接 in-place 修改 `Context` 呢？这是因为 `handle_interrupt` 返回的 `Context` 指针除了存储上下文以外，还提供了内核栈的地址。这个会在后面详细阐述。
>
> 注 2：在 Rust 中，引用 `&mut` 和指针 `*mut` 只是编译器的理解不同，其本质都是一个存储对象地址的寄存器。这里返回值使用指针而不是引用，是因为其指向的位置十分特殊，其生命周期在这里没有意义。

{% label %}os/src/interrupt/handler.rs{% endlabel %}
```rust
/// 中断的处理入口
#[no_mangle]
pub fn handle_interrupt(context: &mut Context, scause: Scause, stval: usize) -> *mut Context {
    /* ... */
}

/// 处理 ebreak 断点
fn breakpoint(context: &mut Context) -> *mut Context {
    println!("Breakpoint at 0x{:x}", context.sepc);
    context.sepc += 2;
    context
}

/// 处理时钟中断
fn supervisor_timer(context: &mut Context) -> *mut Context {
    timer::tick();
    PROCESSOR.get().tick(context)
}
```

可以看到，当发生断点中断时，直接返回原来的上下文（修改一下 `sepc`）；而如果是时钟中断的时候，我们返回了 `PROCESSOR.get().tick(context)` 作为上下文，那它又是怎么工作的呢？

<br/>

## 线程切换

让我们看一下 `Processor::tick` 是如何实现的。

（调度器 `scheduler` 会在后面的小节中讲解，我们只需要知道它能够返回下一个等待执行的线程。）

{% label %}os/src/process/processor.rs{% endlabel %}
```rust
/// 在一个时钟中断时，替换掉 context
pub fn tick(&mut self, context: &mut Context) -> *mut Context {
    // 向调度器询问下一个线程
    if let Some(next_thread) = self.scheduler.get_next() {
        if next_thread == self.current_thread() {
            // 没有更换线程，直接返回 Context
            context
        } else {
            // 准备下一个线程
            let next_context = next_thread.run();
            let current_thread = self.current_thread.replace(next_thread).unwrap();
            // 储存当前线程 Context
            current_thread.park(*context);
            // 返回下一个线程的 Context
            next_context
        }
    } else {
        panic!("all threads terminated, shutting down");
    }
}
```

<br/>

#### 上下文 `Context` 的保存和取出

在线程切换时，我们需要存下前一个线程的 `Context`，为此我们实现 `Thread::park`。

{% label %}os/src/process/thread.rs{% endlabel %}
```rust
/// 发生时钟中断后暂停线程，保存状态
pub fn park(&self, context: Context) {
    // 检查目前线程内的 context 应当为 None
    let mut slot = self.context.lock();
    assert!(slot.is_none());
    // 将 Context 保存到线程中
    slot.replace(context);
}
```

然后，我们需要取出下一个线程的 `Context`，为此我们实现 `Thread::run`。不过这次需要注意的是，启动一个线程除了需要 `Context`，还需要切换页表。这个操作我们也在这个方法中完成。

{% label %}os/src/process/thread.rs{% endlabel %}
```rust
/// 准备执行一个线程
///
/// 激活对应进程的页表，并返回其 Context
pub fn run(&self) -> *mut Context {
    // 激活页表
    self.process.read().memory_set.activate();
    // 取出 Context
    let parked_frame = self.context.lock().take().unwrap();

    if self.process.read().is_user {
        // 用户线程则将 Context 放至内核栈顶
        KERNEL_STACK.push_context(parked_frame)
    } else {
        // 内核线程则将 Context 放至 sp 下
        let context = (parked_frame.sp() - size_of::<Context>()) as *mut Context;
        unsafe { *context = parked_frame };
        context
    }
}
```

思考：在 `run` 函数中，我们在一开始就激活了页表，会不会导致后续流程无法正常执行？

{% reveal %}
> 不会，因为每一个进程的 `MemorySet` 都会映射操作系统的空间，否则在遇到中断的时候，将无法执行异常处理。
{% endreveal %}

<br/>

#### 内核栈？

现在，线程保存 `Context` 都是根据 `sp` 指针，在栈上压入一个 `Context` 来存储。但是，对于一个用户线程，可能只有上帝才知道触发中断时 `sp` 指到了哪里。所以，为了不让一个线程的崩溃导致操作系统的崩溃，我们需要提前准备好内核栈来存储用户线程的 `Context`。在下一节我们将具体讲解该如何做。

<br/>

## 小结

为了实现线程的切换，我们让 `handle_interrupt` 返回一个 `*mut Context`。如果需要切换线程，就将前一个线程的 `Context` 保存起来换上新的线程的 `Context`。而如果不需要切换，那么直接返回原本的 `Context` 即可。
