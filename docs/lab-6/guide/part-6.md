## 条件变量

条件变量（conditional variable）的常见接口是这样的：

- wait：当前线程开始等待这个条件变量
- notify_one：让某一个等待此条件变量的线程继续运行
- notify_all：让所有等待此变量的线程继续运行

条件变量和互斥锁的区别在于，互斥锁解铃还须系铃人，但条件变量可以由任何来源发出 notify 信号。同时，互斥锁的一次 lock 一定对应一次 unlock，但条件变量多次 notify 只能保证 wait 的线程执行次数不超过 notify 次数。

为输入流加入条件变量后，就可以使得调用 `sys_read` 的线程在等待期间保持休眠，不被调度器选中，消耗 CPU 资源。

### 调整调度器

为了继续沿用调度算法，不带来太多修改，我们为线程池单独设立一个「休眠区」，其中保存的线程与调度器互斥。当线程进入等待，就将它从调度器中取出，避免之后再被无用唤起。

{% label %}os/src/process/processor.rs{% endlabel %}
```rust
pub struct Processor {
    /// 当前正在执行的线程
    current_thread: Option<Arc<Thread>>,
    /// 线程调度器，记录活跃线程
    scheduler: SchedulerImpl<Arc<Thread>>,
    /// 保存休眠线程
    sleeping_threads: HashSet<Arc<Thread>>,
}
```

### 实现条件变量

条件变量会被包含在输入流等涉及等待和唤起的结构中，而一个条件变量保存的就是所有等待它的线程。

{% label %}os/src/kernel/condvar.rs{% endlabel %}
```rust
#[derive(Default)]
pub struct Condvar {
    /// 所有等待此条件变量的线程
    watchers: Mutex<VecDeque<Arc<Thread>>>,
}
```

当一个线程调用 `sys_read` 而缓冲区为空时，就会将其加入条件变量的 `watcher` 中，同时在 `Processor` 中移出活跃线程。而当键盘中断到来，读取到字符时，就会将线程重新放回调度器中，准备下一次调用。

开放思考：如果多个线程同时等待输入流会怎么样？有什么解决方案吗？
