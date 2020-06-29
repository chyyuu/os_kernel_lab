## 物理内存管理

### 物理页

通常，我们在分配物理内存时并不是以字节为单位，而是以一**物理页(Frame)**，即连续的 4 KB 字节为单位分配。我们希望用物理页号（Physical Page Number，PPN）来代表一物理页，实际上代表物理地址范围在 $$[\text{PPN}\times 4\text{KB},(\text{PPN}+1)\times 4\text{KB})$$ 的一物理页。

不难看出，物理页号与物理页形成一一映射。为了能够使用物理页号这种表达方式，每个物理页的开头地址必须是 4 KB 的倍数。但这也给了我们一个方便：对于一个物理地址，其除以 4096（或者说右移 12 位）的商即为这个物理地址所在的物理页号。

同样的，我们还是用一个新的结构来封装一下物理页，一是为了和其他类型地址作区分；二是我们可以同时实现一些页帧和地址相互转换的功能。为了后面的方便，我们也把虚拟地址和虚拟页（概念还没有涉及，后面的指导会进一步讲解）一并实现出来，这部分代码请参考 `os/src/memory/address.rs`。

同时，我们也需要在 `os/src/memory/config.rs` 中加入相关的设置：

{% label %}os/src/memory/config.rs{% endlabel %}
```rust
/// 页 / 帧大小，必须是 2^n
pub const PAGE_SIZE: usize = 4096;

/// 可以访问的内存区域起始地址
pub const MEMORY_START_ADDRESS: PhysicalAddress = PhysicalAddress(0x8000_0000);
/// 可以访问的内存区域结束地址
pub const MEMORY_END_ADDRESS: PhysicalAddress = PhysicalAddress(0x8800_0000);
```

### 分配和回收

为了方便管理所有的物理页，我们需要实现一个分配器可以进行分配和回收的操作，在这之前，我们需要先把物理页的概念进行封装。注意到，物理页在实际上其实是连续的一片内存区域，这里我们只是把区域的其实物理地址封装到了一个 `FrameTracker` 里面。

{% label %}os/src/memory/frame_tracker.rs{% endlabel %}
```rust
/// 分配出的物理页
///
/// # `Tracker` 是什么？
/// 太长不看
/// > 可以理解为 [`Box`](alloc::boxed::Box)，而区别在于，其空间不是分配在堆上，
/// > 而是直接在内存中划一片（一个物理页）。
///
/// 在我们实现操作系统的过程中，会经常遇到『指定一块内存区域作为某种用处』的情况。
/// 此时，我们说这块内存可以用，但是因为它不在堆栈上，Rust 编译器并不知道它是什么，所以
/// 我们需要 unsafe 地将其转换为 `&'static mut T` 的形式（`'static` 一般可以省略）。
///
/// 但是，比如我们用一块内存来作为页表，而当这个页表我们不再需要的时候，就应当释放空间。
/// 我们其实更需要一个像『创建一个有生命期的对象』一样的模式来使用这块内存。因此，
/// 我们不妨用 `Tracker` 类型来封装这样一个 `&'static mut` 引用。
///
/// 使用 `Tracker` 其实就很像使用一个 smart pointer。如果需要引用计数，
/// 就在外面再套一层 [`Arc`](alloc::sync::Arc) 就好
pub struct FrameTracker(PhysicalAddress);

impl FrameTracker {
    /// 帧的物理地址
    pub fn address(&self) -> PhysicalAddress {
        self.0
    }
    /// 帧的物理页号
    pub fn page_number(&self) -> PhysicalPageNumber {
        PhysicalPageNumber::from(self.0)
    }
}

/// 帧在释放时会放回 [`static@FRAME_ALLOCATOR`] 的空闲链表中
impl Drop for FrameTracker {
    fn drop(&mut self) {
        FRAME_ALLOCATOR.lock().dealloc(self);
    }
}
```

这里，我们实现了 `FrameTracker` 这个结构，而区分于实际在内存中的 4KB 大小的 "Frame"，我们设计的初衷是分配器分配给我们 `FrameTracker` 作为一个帧的标识，而随着不再需要这个物理页，我们需要回收，我们利用 Rust 的 drop 机制在析构的时候自动实现回收。

最后，我们封装一个物理页分配器，为了符合更 Rust 规范的设计，这个分配器将不涉及任何的具体算法，具体的算法将用一个名为 `Allocator` 的 Rust trait 封装起来，而我们的 `FrameAllocator` 会依赖于具体的 trait 实现例化。

{% label %}os/src/memory/frame/allocator.rs{% endlabel %}
```rust
lazy_static! {
    /// 帧分配器
    pub static ref FRAME_ALLOCATOR: Mutex<FrameAllocator<AllocatorImpl>> = Mutex::new(FrameAllocator::new(Range::from(
            PhysicalPageNumber::ceil(PhysicalAddress::from(*KERNEL_END_ADDRESS))..PhysicalPageNumber::floor(MEMORY_END_ADDRESS),
        )

    ));
}

/// 基于线段树的帧分配 / 回收
pub struct FrameAllocator<T: Allocator> {
    /// 可用区间的起始
    start_ppn: PhysicalPageNumber,
    /// 分配器
    allocator: T,
}

impl<T: Allocator> FrameAllocator<T> {
    /// 创建对象
    pub fn new(range: impl Into<Range<PhysicalPageNumber>> + Copy) -> Self {
        FrameAllocator {
            start_ppn: range.into().start,
            allocator: T::new(range.into().len()),
        }
    }

    /// 分配帧，如果没有剩余则返回 `Err`
    pub fn alloc(&mut self) -> MemoryResult<FrameTracker> {
        self.allocator
            .alloc()
            .ok_or("no available frame to allocate")
            .map(|offset| FrameTracker::from(self.start_ppn + offset))
    }

    /// 将被释放的帧添加到空闲列表的尾部
    ///
    /// 这个函数会在 [`FrameTracker`] 被 drop 时自动调用，不应在其他地方调用
    pub(super) fn dealloc(&mut self, frame: &FrameTracker) {
        self.allocator.dealloc(frame.page_number() - self.start_ppn);
    }
}

```

这个分配器会以一个 `PhysicalPageNumber` 的 `Range` 初始化，然后把起始地址记录下来，把整个区间的长度告诉具体的分配器算法，当分配的时候就从算法中取得一个可用的位置作为 `offset`，再加上起始地址返回回去。

有关具体的算法，我们封装了一个分配器需要的 Rust trait：

{% label %}os/src/data_structure/mod.rs{% endlabel %}
```rust
/// 分配器：固定容量，每次分配 / 回收一个元素
pub trait Allocator {
    /// 给定容量，创建分配器
    fn new(capacity: usize) -> Self;
    /// 分配一个元素，无法分配则返回 `None`
    fn alloc(&mut self) -> Option<usize>;
    /// 回收一个元素
    fn dealloc(&mut self, index: usize);
}
```

并在 `os/src/data_structure/` 中分别实现了链表和线段树算法，具体内容可以参考代码。

我们注意到，我们使用了 `lazy_static!` 和 `Mutex` 来包装分配器。需要知道，对于 `static mut` 类型的修改操作是 unsafe 的。我们之后会提到线程的概念，对于静态数据，所有的线程都能访问。当一个线程正在访问这段数据的时候，如果另一个线程也来访问，就可能会产生冲突，并带来难以预测的结果。

所以我们的方法是使用 `spin::Mutex<T>` 给这段数据加一把锁，一个线程试图通过 `lock()` 打开锁来获取内部数据的可变引用，如果钥匙被别的线程所占用，那么这个线程就会一直卡在这里；直到那个占用了钥匙的线程对内部数据的访问结束，锁被释放，将钥匙交还出来，被卡住的那个线程拿到了钥匙，就可打开锁获取内部引用，访问内部数据。

这里使用的是 `spin::Mutex<T>`，我们需要在 `os/Cargo.toml` 中添加依赖。幸运的是，它也无需任何操作系统支持（即支持 `no_std`），我们可以放心使用。

最后，在把新写的模块加载进来，并在 main 函数中进行简单的测试：

{% label %}os/src/main.rs{% endlabel %}
```rust
/// Rust 的入口函数
///
/// 在 `_start` 为我们进行了一系列准备之后，这是第一个被调用的 Rust 函数
#[no_mangle]
pub extern "C" fn rust_main() -> ! {
    // 初始化各种模块
    interrupt::init();
    memory::init();

    // 物理页分配
    for _ in 0..2 {
        let frame_0 = match memory::frame::FRAME_ALLOCATOR.lock().alloc() {
            Result::Ok(frame_tracker) => frame_tracker,
            Result::Err(err) => panic!("{}", err)
        };
        let frame_1 = match memory::frame::FRAME_ALLOCATOR.lock().alloc() {
            Result::Ok(frame_tracker) => frame_tracker,
            Result::Err(err) => panic!("{}", err)
        };
        println!("{} and {}", frame_0.address(), frame_1.address());
    }

    loop{}
}
```

可以看到类似这样的输出：

{% label %}运行输出{% endlabel %}
```
PhysicalAddress(0x80a14000) and PhysicalAddress(0x80a15000)
PhysicalAddress(0x80a14000) and PhysicalAddress(0x80a15000)
```

我们可以看到 `frame_0` 和 `frame_1` 会被自动析构然后回收，第二次又分配同样的地址。

### 思考

运行下面的代码：

{% label %}os/src/main.rs{% endlabel %}
```rust
/// Rust 的入口函数
///
/// 在 `_start` 为我们进行了一系列准备之后，这是第一个被调用的 Rust 函数
#[no_mangle]
pub extern "C" fn rust_main() -> ! {
    // 初始化各种模块
    interrupt::init();
    memory::init();

    // 物理页分配
    match memory::frame::FRAME_ALLOCATOR.lock().alloc() {
            Result::Ok(frame_tracker) => frame_tracker,
            Result::Err(err) => panic!("{}", err)
    };

    loop{}
}
```

思考，和上面的代码有何不同，我们的设计是否存在一些语法上的设计缺陷？

{% reveal %}
> 这里的 `frame_tracker` 变量会在 `match` 语法里面析构。但是析构的时候，外层的 `lock()` 函数还没有释放锁，这样写会导致死锁。
>
{% endreveal %}

<!-- TODO 改成无锁的（因为也只是内核访问） -->