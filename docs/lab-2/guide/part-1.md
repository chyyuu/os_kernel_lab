## 动态内存分配

我们之前在 C++ 语言等中使用过 `malloc` 等动态内存分配方法，与在编译期就已完成的静态内存分配相比，动态内存分配可以根据程序运行时状态修改内存申请的时机及大小，显得更为灵活，但是这是需要操作系统的支持的，同时也会带来一些开销。

我们的内核中也需要动态内存分配。典型的应用场景有：

- `Box<T>` ，你可以理解为它和 `malloc` 有着相同的功能；
- 引用计数 `Rc<T>`，原子引用计数 `Arc<T>`，主要用于在引用计数清零，即某对象不再被引用时，对该对象进行自动回收；
- 一些 std 中的数据结构，如 `Vec` 和 `HashMap` 等。

为了在我们的内核中支持动态内存分配，在 Rust 语言中，我们需要实现 `Trait GlobalAlloc`，将这个类实例化，并使用语义项 `#[global_allocator]` 进行标记。这样的话，编译器就会知道如何进行动态内存分配。

为了实现 `Trait GlobalAlloc`，我们需要支持这么两个函数：

```rust
unsafe fn alloc(&self, layout: Layout) -> *mut u8;
unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout);
```

可见我们要分配/回收一块虚拟内存。

那么这里面的 `Layout` 又是什么呢？从文档中可以找到，它有两个字段：`size` 表示要分配的字节数，`align` 则表示分配的虚拟地址的最小对齐要求，即分配的地址要求是 `align` 的倍数。这里的 `align` 必须是 2 的幂次。

也就表示，我们的需求是分配一块连续的、大小至少为 `size` 字节的虚拟内存，且对齐要求为 `align` 。

### 连续内存分配算法

假设我们已经有一整块虚拟内存用来分配，那么如何进行分配呢？

我们可能会想到一些简单粗暴的方法，比如对于一个分配任务，贪心地将其分配到可行的最小地址去。这样一直分配下去的话，我们分配出去的内存都是连续的，看上去很合理的利用了内存。

但是一旦涉及到回收的话，设想我们在连续分配出去的很多块内存中间突然回收掉一块，它虽然是可用的，但是由于上下两边都已经被分配出去，它就只有这么大而不能再被拓展了，这种可用的内存我们称之为**外碎片**。

随着不断回收会产生越来越多的碎片，某个时刻我们可能会发现，需要分配一块较大的内存，几个碎片加起来大小是足够的，但是单个碎片是不够的。我们会想到通过**碎片整理**将几个碎片合并起来。但是这个过程的开销极大。

老师在课堂上介绍了若干管理分配和碎片的算法，包括伙伴系统（Buddy System）和 SLAB 分配器等算法，我们在这里使用 Buddy System 来实现这件事情。

### 支持动态内存分配

为了避免重复造轮子，我们可以直接开一个静态的 8M 数组作为堆的空间，然后调用 [@jiege](https://github.com/jiegec/) 开发的 Buddy System Allocator。

{% label %}os/src/memory/config.rs{% endlabel %}
```rust
/// 操作系统动态分配内存所用的堆大小（8M）
pub const KERNEL_HEAP_SIZE: usize = 0x80_0000;
```

{% label %}os/src/memory/heap.rs{% endlabel %}
```rust
/// 进行动态内存分配所用的堆空间
/// 
/// 大小为 [`KERNEL_HEAP_SIZE`]  
/// 这段空间编译后会被放在操作系统执行程序的 bss 段
static mut HEAP_SPACE: [u8; KERNEL_HEAP_SIZE] = [0; KERNEL_HEAP_SIZE];

/// 堆，动态内存分配器
/// 
/// ### `#[global_allocator]`
/// [`LockedHeap`] 实现了 [`alloc::alloc::GlobalAlloc`] trait，
/// 可以为全局需要用到堆的地方分配空间。例如 `Box` `Arc` 等
#[global_allocator]
static HEAP: LockedHeap = LockedHeap::empty();

/// 初始化操作系统运行时堆空间
pub fn init() {
    // 告诉分配器使用这一段预留的空间作为堆
    unsafe {
        HEAP.lock().init(
            HEAP_SPACE.as_ptr() as usize, KERNEL_HEAP_SIZE
        )
    }
}

/// 空间分配错误的回调，直接 panic 退出
#[alloc_error_handler]
fn alloc_error_handler(_: alloc::alloc::Layout) -> ! {
    panic!("alloc error")
}
```

同时还有一些模块调用等细节代码，这里不再贴出，请参考完成本章后的仓库中的代码。

### 动态内存分配测试

现在我们来测试一下动态内存分配是否有效，分配一个动态数组：

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

    // 动态内存分配测试
    use alloc::boxed::Box;
    use alloc::vec::Vec;
    let v = Box::new(5);
    assert_eq!(*v, 5);
    let mut vec = Vec::new();
    for i in 0..10000 {
        vec.push(i);
    }
    for i in 0..10000 {
        assert_eq!(vec[i], i);
    }
    println!("heap test passed");

    loop{}
}
```

最后，运行一下会看到 `heap test passed` 类似的输出。有了这个工具之后，后面我们就可以使用一系列诸如 `Vec` 等基于动态分配实现的库中的结构了。

### 思考

动态分配的内存地址在哪个范围里？

{% reveal %}
> 在 .bss 段中，因为我们用来存放动态分配的这段是一个静态的没有初始化的数组，算是内核代码的一部分。
{% endreveal %}

