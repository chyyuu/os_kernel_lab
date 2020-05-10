# 调度器

## 处理器抽象

我们已经可以创建和保存线程了，现在，我们再抽象出『处理器』来存放线程池。同时，也需要单独存放目前正在执行的线程（即中断前执行的线程，因为操作系统在工作时一定属于中断之中）。

{% label %}os/src/process/processor.rs{% endlabel %}
```rust
lazy_static! {
    /// 全局的 [`Processor`]
    pub static ref PROCESSOR: UnsafeWrapper<Processor> = Default::default();
}

/// 线程调度和管理
#[derive(Default)]
pub struct Processor {
    /// 当前正在执行的线程
    current_thread: Option<Arc<Thread>>,
    /// 线程调度器，记录所有线程
    scheduler: SchedulerImpl<Arc<Thread>>,
}
```

注意到这里我们用了一个 `UnsafeWrapper`，这个东西相当于 Rust 提供的 `UnsafeCell`，或者 C 语言的指针：任何线程都可以随时从中获取一个 `&'static mut` 引用。由于在我们的设计中，**只有时钟中断（以及未来的系统调用）时可以使用 `PROCESSOR`**，而在此过程中，操作系统是关闭时钟中断的。因此，这里使用 `UnsafeCell` 是安全的。

<br/>

## 调度器

调度器的算法有许多种，我们将它提取出一个 trait 作为接口

{% label %}(os/src/) algorithm/src/scheduler/mod.rs{% endlabel %}
```rust
/// 线程调度器
///
/// 这里 `ThreadType` 就是 `Arc<Thread>`
pub trait Scheduler<ThreadType: Clone + Eq>: Default {
    /// 向线程池中添加一个线程
    fn add_thread<T>(&mut self, thread: ThreadType, priority: T);
    /// 获取下一个时间段应当执行的线程
    fn get_next(&mut self) -> Option<ThreadType>;
    /// 移除一个线程
    fn remove_thread(&mut self, thread: ThreadType);
    /// 设置线程的优先级
    fn set_priority<T>(&mut self, thread: ThreadType, priority: T);
}
```

具体的算法就不在此展开了，我们可以参照目录下的一些样例。

<br/>

## 运行！

最后，让我们补充 `Processor::run` 的实现，让我们运行起第一个线程！

{% label %}os/src/process/processor.rs: impl Processor{% endlabel %}
```rust
/// 第一次开始运行
pub fn run(&mut self) -> ! {
    // interrupt.asm 中的标签
    extern "C" {
        fn __restore(context: usize);
    }
    // 从 current_thread 中取出 Context
    let context = self.current_thread().run();
    // 从此将没有回头
    unsafe {
        __restore(context as usize);
    }
    unreachable!()
}
```

修改 `main.rs`，我们就可以跑起来多线程了。

{% label %}os/src/main.rs{% endlabel %}
```rust
#[no_mangle]
pub extern "C" fn rust_main() -> ! {
    memory::init();
    interrupt::init();

    // 新建一个带有内核映射的进程。需要执行的代码就在内核中
    let process = Process::new_kernel().unwrap();

    for message in 0..8 {
        let thread = Thread::new(
            process.clone(),            // 使用同一个进程
            sample_process as usize,    // 入口函数
            Some(&[message]),           // 参数
        ).unwrap();
        PROCESSOR.get().add_thread(thread);
    }

    // 把多余的 process 引用丢弃掉
    drop(process);

    PROCESSOR.get().run();
}

fn sample_process(message: usize) {
    for i in 0..1000000 {
        if i % 200000 == 0 {
            println!("thread {}", message);
        }
    }
}

```

<br/>

运行一下，我们会得到类似的输出：

{% label %}运行输出{% endlabel %}
```
thread 7
thread 6
thread 5
thread 4
thread 3
thread 2
thread 1
thread 0
thread 6
thread 5
thread 4
thread 2
thread 1
thread 7
thread 3
thread 0
100 tick
thread 7
thread 6
thread 5
thread 4
thread 3
thread 2
thread 1
thread 0

...
```
