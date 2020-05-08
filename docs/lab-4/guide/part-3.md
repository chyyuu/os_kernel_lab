## 调度器

在上面的小节中，我们完成了对进程和线程的封装，下面为了能让他们运行起来，我们来抽象一个处理器，所谓的处理器，这里更像是一个 CPU 的核心的概念，为了表示执行流这个概念，其实里面包含一个当前执行的线程就可以了，但是在软件层面上，我们还关心调度这个概念，就是说当一个线程运行了一段时间之后，需要一个调度算法来选择下一个需要运行的线程。

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
    /// 线程调度器，其中不包括正在执行的线程
    scheduler: Scheduler,
}
```

注意到这里我们用了一个 `UnsafeWrapper`，这个东西相当于 Rust 提供的 `UnsafeCell`，或者 C 语言的指针：任何线程都可以随时从中获取一个 `&'static mut` 引用。由于在我们的设计中，**只有时钟中断（以及未来的系统调用）时可以使用 `PROCESSOR`**，而在此过程中，操作系统是关闭中断的。因此，这里使用 `UnsafeCell` 是安全的。

而关于具体的调度涉及到的各种算法，我们会在下一个实验中体现，不过为了展示我们前面工作的效果，我们还是需要一个简单的调度器，这里的调度器就是每次换一个线程，轮流换，执行一个时间片段结束之后就把这个线程放在队尾，然后执行队首的线程。

{% label %}os/src/process/scheduler.rs{% endlabel %}
```rust
//! 线程调度器 [`Scheduler`]

use super::*;
use alloc::collections::LinkedList;

/// 线程调度器（FIFO 实现）
#[derive(Default)]
pub struct Scheduler {
    pool: LinkedList<Arc<Thread>>,
}

impl Scheduler {
    pub fn store(&mut self, thread: Arc<Thread>) {
        self.pool.push_back(thread);
    }

    pub fn get(&mut self) -> Arc<Thread> {
        self.pool.pop_front().unwrap()
    }
}
```

随后，我们来实现加入一个新的线程：

{% label %}os/src/process/processor.rs: impl Processor{% endlabel %}
```rust
/// 添加一个待执行的线程
pub fn schedule_thread(&mut self, thread: Arc<Thread>) {
    // 如果 current_thread 为空就添加为 current_thread，否则丢给 scheduler
    if self.current_thread.is_none() {
        self.current_thread.replace(thread);
    } else {
        self.scheduler.store(thread);
    }
}
```

这里的行为比较简单，我们用 `current_thread` 表示当前线程，如果现在还没有（还没有初始化），就把线程放在 `current_thread` 里面，否则放在调度器里面。

然后是当时钟中断到来时取出暂停当前的线程然后换一个新的线程执行（这里和上一个小节的 `PROCESSOR.get().tick(context)` 呼应，处理时钟中断的函数会返回一个新的 `Context`）：

{% label %}os/src/process/processor.rs: impl Processor{% endlabel %}
```rust
/// 在一个时钟中断时，替换掉 context
pub fn tick(&mut self, context: &mut Context) -> *mut Context {
    // 暂停当前线程
    let current_thread = self.current_thread.take().unwrap();
    current_thread.park(*context);
    // 将其放回调度器
    self.scheduler.store(current_thread);

    // 取出一个线程
    let next_thread = self.scheduler.get();
    let context = next_thread.run();
    // 作为当前线程
    self.current_thread.replace(next_thread);
    context
}
```

最后的最后，需要注意到我们开始从 `_start` 到 `rust_main`，这个过程一直是一个所谓的启动线程在做，后面，为了完全替换为我们新的逻辑和管理，这个线程我们将完全扔掉，再也不回头，而做这件事情的也是 `Processor` 这个类：

{% label %}os/src/process/processor.rs: impl Processor{% endlabel %}
```rust
/// 第一次开始运行
///
/// 从 `current_thread` 中取出 [`Context`]，然后直接调用 `interrupt.asm` 中的 `__restore`
/// 来从 `Context` 中继续执行该线程。
///
/// 注意调用 `run()` 的线程会就此步入虚无，不再被使用
pub fn run(&mut self) -> ! {
    // interrupt.asm 中的标签
    extern "C" {
        fn __restore(context: *mut Context);
    }
    // 从 current_thread 中取出 Context
    let thread = self.current_thread.as_ref().unwrap().clone();
    let context = thread.run();
    // 因为这个线程（指的不是 thread，是运行 run 函数的线程）不会回来回收，所以手动 drop 掉 thread 的一个 Arc
    drop(thread);
    // 从此将没有回头
    unsafe {
        __restore(context);
    }
    unreachable!()
}
```

可以看到，这个函数把 `current_thread` 的内容取了出来调用了 `__restore` 来实现跳转，从此再不会执行下面的逻辑，而注意到这里有一个 `thread` 的引用计数，因为这个函数不会结束，我们需要手动把引用计数去掉。

### 测试

终于，我们搞定了全部的逻辑（看起来是这样的）！下面我们来试一试：

{% label %}os/src/main.rs{% endlabel %}
```rust
/// Rust 的入口函数
///
/// 在 `_start` 为我们进行了一系列准备之后，这是第一个被调用的 Rust 函数
#[no_mangle]
pub extern "C" fn rust_main() -> ! {
    memory::init();
    interrupt::init();

    let process = Process::new_kernel().unwrap();

    let thread = Thread::new(process.clone(), sample_process as usize, Some(&[12345usize])).unwrap();
    PROCESSOR.get().schedule_thread(thread);
    let thread = Thread::new(process, sample_process as usize, Some(&[12345usize])).unwrap();
    PROCESSOR.get().schedule_thread(thread);

    PROCESSOR.get().run();
}

fn sample_process(arg: usize) {
    println!("sample_process called with argument {}", arg);
    for _ in 0..3000000 {}
    println!("i'm back");
    loop {}
}
```

我们首先新建了一个内核进程，然后再进程里面放了两个线程，最后把两个线程放入 `PROCESSOR` 里面运行，这看起来没有问题，但是仔细想一想，如果在 `interrupt::init()` 和 `PROCESSOR.get().run()` 之间发生了中断怎么办呢？这将会产生无法启动的问题。但是需要注意到的是，因为我们在新建 `Thread` 的过程中设置好了 `sstatus`，在切换到对应的线程时会开启中断，所以这里的 `interrupt::init()` 完全可以把中断关掉（让 `sie` 为 0），等到第一个线程启动时再自动打开。

{% label %}os/interrupt/timer.rs{% endlabel %}
```rust
/// 初始化时钟中断
///
/// 开启时钟中断使能，并且预约第一次时钟中断
pub fn init() {
    unsafe {
        // 开启 STIE，允许时钟中断
        sie::set_stimer();
        // （删除）开启 SIE（不是 sie 寄存器），允许内核态被中断打断
        // sstatus::set_sie();
    }
    // 设置下一次时钟中断
    set_next_timeout();
}
```

运行一下，我们会得到类似的输出：

{% label %}运行输出{% endlabel %}
```
sample_process called with argument 12345
sample_process called with argument 12345
100 tick
200 tick
i'm back
i'm back
300 tick
```

可以看到两个线程都已经是运行好的状态了，至此，我们也完成了全部本章全部内容。但是，仔细想一想，现在的逻辑还没有大问题？

### 思考

可以看到我们的设计中用了大量的锁结构，很多都是为了让 Rust 知道我们是安全的，而且大部分情况下我们**仅仅**会在中断发生的时候来使用这些逻辑，这意味着，只要内核线程里面不用，就不会发生死锁，但是真的是这样吗？即使我们不在内核中使用各种 `Processor` 和 `Thread` 等等的逻辑，仅仅完成一些简单的运算，真的没有死锁吗？

{% reveal %}
> 会有死锁，比如我们在内核线程中构造一个 `Vec`，然后在里面 push 几个元素，这个时候就可能产生死锁。
>
> 需要注意到，我们的动态分配器是一个 `LockedHeap`，是外面加了锁的一个分配器，如果在线程里面 push 的过程中需要动态分配，然后正好在上完锁而且没有释放锁的时候产生了中断，而中断中我们的 `Scheduler` 也用到了 `Vec`，这个时候会再去锁住，但是又拿不到，同时需要注意的是在处理中断本身时，我们的时钟中断是关掉的，这意味着我们的锁会一直去申请，就形成了类似死锁的死循环。
>
> 解决这个问题需要把申请到锁之后加上关闭中断，通过这种抢占式的方法彻底执行完分配逻辑之后再关闭锁同时打开中断。这个问题是一个设计上的取舍，如果我们不支持内核抢占，就需要很多精妙的设计来绕开这个问题。在这里，我们先不会理会这个问题。
>
{% endreveal %}