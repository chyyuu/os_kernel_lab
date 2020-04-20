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

/// 可用的首个物理页号
pub const BEGIN_PPN: PhysicalPageNumber = PhysicalPageNumber::ceil(MEMORY_START_ADDRESS);
/// 可用的最后物理页号 + 1
pub const END_PPN: PhysicalPageNumber = PhysicalPageNumber::floor(MEMORY_END_ADDRESS);
```

### 分配和回收

为了方便管理所有的物理页，我们需要实现一个分配器可以进行分配和回收的操作，我们使用类似链表的 `Vec` 来做这件事情，首先先封装一下帧的相关概念。

{% label %}os/src/memory/frame.rs{% endlabel %}
```rust
//! 物理帧的类

use crate::memory::{
    address::*,
    frame::allocator::FRAME_ALLOCATOR,
};

/// 分配出的物理帧
///
/// # `Tracker` 是什么？
/// 太长不看
/// > 可以理解为 [`Box`](alloc::boxed::Box)，而区别在于，其空间不是分配在堆上，
/// > 而是直接在内存中划一片（一个物理帧）。
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
pub struct FrameTracker(pub(super) PhysicalAddress);

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

/// 帧在释放时会放回 [`frame_allocator`] 的空闲链表中
impl Drop for FrameTracker {
    fn drop(&mut self) {
        FRAME_ALLOCATOR.lock().dealloc(self);
    }
}
```

这里，我们实现了 `FrameTracker` 这个结构，而区分于实际在内存中的 4KB 大小的 "Frame"，我们设计的初衷是分配器分配给我们 `FrameTracker` 作为一个帧的标识，而随着不再需要这个物理帧，我们需要回收，我们利用 Rust 的 drop 机制在析构的时候自动实现回收。

最后给出我们实现分配的算法：

{% label %}os/src/memory/frame/allocator.rs{% endlabel %}
```rust
//! 使用链表管理帧
//!
//! 返回的 [`FrameTracker`] 类型代表一个帧，它在被 drop 时会自动将空间补回分配器中。
//!
//! # 为何 [`FrameAllocator`] 只有一个 usize 大小？
//! 这是一个只有在开发操作系统时可以完成的操作：随意访问地址和读写内存。
//! 我们实现的是内存按帧分配的流程，此时我们就可以使用那些还未被分配的帧来记录数据。
//!
//! 因此 [`FrameAllocator`] 记录一个指针指向某一个空闲的帧，
//! 而每个空闲的帧指向再下一个空闲的帧，直到最后一个指向 0 即可。
//! 注意所有地址使用的是虚拟地址（使用线性映射）。
//!
//! 而为了方便初始化，我们再在帧中记录『连续空闲帧数』，那么最初只需要初始化一个帧即可。

use super::frame::*;
use crate::memory::{address::*, config::*};
use alloc::{vec, vec::Vec};
use lazy_static::*;
use spin::Mutex;

lazy_static! {
    /// 帧分配器
    pub static ref FRAME_ALLOCATOR: Mutex<FrameAllocator> = Mutex::new(FrameAllocator::new());
}

/// 基于链表的帧分配 / 回收
pub struct FrameAllocator {
    /// 记录空闲帧的列表，每一项表示地址、从该地址开始连续多少帧空闲
    free_frame_list: Vec<(PhysicalAddress, usize)>,
}

impl FrameAllocator {
    /// 创建对象，其中 \[[`BEGIN_VPN`], [`END_VPN`]) 区间内的帧在其空闲列表中
    pub fn new() -> Self {
        // 定位到第一个可用的物理帧
        let first_frame_ppn = PhysicalPageNumber::ceil(*KERNEL_END_ADDRESS);
        let first_frame_address = PhysicalAddress::from(first_frame_ppn);
        FrameAllocator {
            free_frame_list: vec![(first_frame_address, END_PPN - first_frame_ppn)],
        }
    }

    /// 取列表末尾元素来分配帧
    ///
    /// - 如果末尾元素 `size > 1`，则相应修改 `size` 而保留元素
    /// - 如果没有剩余则返回 `Err`
    pub fn alloc(&mut self) -> Result<FrameTracker, &'static str> {
        if let Some((address, page_count)) = self.free_frame_list.pop() {
            // 如果有元素，将要分配该地址对应的帧
            if page_count > 1 {
                // 如果有连续的多个帧空余，则只取出一个，放回剩余部分
                self.free_frame_list
                    .push((address + PAGE_SIZE, page_count - 1));
            }
            Ok(FrameTracker(address))
        } else {
            // 链表已空，返回 `Err`
            Err("no available frame to allocate")
        }
    }

    /// 将被释放的帧添加到空闲列表的尾部
    ///
    /// 这个函数会在 [`FrameTracker`] 被 drop 时自动调用，不应在其他地方调用
    pub(super) fn dealloc(&mut self, frame: &FrameTracker) {
        self.free_frame_list.push((frame.address(), 1));
    }
}
```

这个分配器会把连续的物理页放在一起，每次申请的时候直接把最后一个拿出来分配过去，回收的时候直接把回收回来的帧 push 在末尾。

我们注意到，我们使用了 `lazy_static!` 和 `Mutex` 来包装分配器。需要注意到，对于 `static mut` 类型的修改操作是 unsafe 的。我们之后会提到线程的概念，对于静态数据，所有的线程都能访问。当一个线程正在访问这段数据的时候，如果另一个线程也来访问，就可能会产生冲突，并带来难以预测的结果。

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
PhysicalAddress(0x80a13000) and PhysicalAddress(0x80a14000)
PhysicalAddress(0x80a13000) and PhysicalAddress(0x80a14000)
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
{% endreveal %}

<!-- TODO 改成无锁的（因为也只是内核访问） -->