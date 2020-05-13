## 实现页表

为了实现 Sv39 页表，我们的思路是把一个分配好的物理页（即会自动销毁的 `FrameTracker`）拿来把数据填充作为页表，而页表中的每一项是一个 8 字节的页表项。

对于页表项的位级别的操作，我们首先需要加入两个关于位操作的 crate：

{% label %}os/Cargo.toml{% endlabel %}
```toml
bitflags = "1.2.1"
bit_field = "0.10.0"
```

然后，首先了构建了关于虚拟页号获得三级 VPN 的函数：
{% label %}os/src/memory/address.rs{% endlabel %}
```rust
impl VirtualPageNumber {
    /// 得到一、二、三级页号
    pub fn levels(self) -> [usize; 3] {
        [
            self.0.get_bits(18..27),
            self.0.get_bits(9..18),
            self.0.get_bits(0..9),
        ]
    }
}
```

### 页表项

后面，我们来实现页表项，其实就是对一个 `usize`（8 字节）的封装，同时我们可以用刚刚加入的 bit 级别操作的 crate 对其实现一些取出特定段的方便后续实现的函数：

{% label %}os/src/memory/mapping/page_table_entry.rs{% endlabel %}
```rust
/// Sv39 结构的页表项
#[derive(Copy, Clone, Default)]
pub struct PageTableEntry(usize);

impl PageTableEntry {
    /// 将相应页号和标志写入一个页表项
    pub fn new(page_number: PhysicalPageNumber, flags: Flags) -> Self {
        Self(
            *0usize
                .set_bits(..8, flags.bits() as usize)
                .set_bits(10..54, page_number.into()),
        )
    }
    /// 获取页号
    pub fn page_number(&self) -> PhysicalPageNumber {
        PhysicalPageNumber::from(self.0.get_bits(10..54))
    }
    /// 获取地址
    pub fn address(&self) -> PhysicalAddress {
        PhysicalAddress::from(self.page_number())
    }
    /// 获取标志位
    pub fn flags(&self) -> Flags {
        unsafe { Flags::from_bits_unchecked(self.0.get_bits(..8) as u8) }
    }
    /// 是否为空（可能非空也非 Valid）
    pub fn is_empty(&self) -> bool {
        self.0 == 0
    }
}

impl core::fmt::Debug for PageTableEntry {
    fn fmt(&self, formatter: &mut core::fmt::Formatter) -> core::fmt::Result {
        formatter
            .debug_struct("PageTableEntry")
            .field("value", &self.0)
            .field("page_number", &self.page_number())
            .field("flags", &self.flags())
            .finish()
    }
}

bitflags! {
    /// 页表项中的 8 个标志位
    #[derive(Default)]
    pub struct Flags: u8 {
        /// 有效位
        const VALID =       1 << 0;
        /// 可读位
        const READABLE =    1 << 1;
        /// 可写位
        const WRITABLE =    1 << 2;
        /// 可执行位
        const EXECUTABLE =  1 << 3;
        /// 用户位
        const USER =        1 << 4;
        /// 全局位，我们不会使用
        const GLOBAL =      1 << 5;
        /// 已使用位，用于替换算法
        const ACCESSED =    1 << 6;
        /// 已修改位，用于替换算法
        const DIRTY =       1 << 7;
    }
}
```

### 页表

有了页表项，512 个连续的页表项组成的 4KB 物理页，同时再加上一些诸如多级添加映射的功能，就可以封装为页表。

{% label %}os/src/memory/mapping/page_table.rs{% endlabel %}
```rust
/// 存有 512 个页表项的页表
///
/// 注意我们不会使用常规的 Rust 语法来创建 `PageTable`。相反，我们会分配一个物理页，
/// 其对应了一段物理内存，然后直接把其当做页表进行读写。我们会在操作系统中用一个『指针』
/// [`PageTableTracker`] 来记录这个页表。
#[repr(C)]
pub struct PageTable {
    pub entries: [PageTableEntry; PAGE_SIZE / 8],
}

impl PageTable {
    /// 将页表清零
    pub fn zero_init(&mut self) {
        self.entries = [Default::default(); PAGE_SIZE / 8];
    }
}
```

然而，我们不会把这个巨大的数组在函数之间不停传递，我们这里的思路也同样更多利用 Rust 的特性，所以做法是利用一个 `PageTableTracker` 的结构对 `FrameTracker` 封装，但是里面的行为是对 `FrameTracker` 记录的物理页当成 `PageTable` 进行操作。同时，这个 `PageTableTracker` 和 `PageTableEntry` 也通过一些 Rust 中的自动解引用的特性为后面的实现铺平了道路，比如我们可以直接把 `PageTableTracker` 当成 `PageTable` 对待，同时，如果一个 `PageTableEntry` 指向的是另一个 `PageTable` 我们可以直接方便的让编译器自动完成这些工作。

{% label %}os/src/memory/mapping/page_table.rs{% endlabel %}
```rust
/// 类似于 [`FrameTracker`]，用于记录某一个内存中页表
///
/// 注意到，『真正的页表』会放在我们分配出来的物理页当中，而不应放在操作系统的运行栈或堆中。
/// 而 `PageTableTracker` 会保存在某个线程的元数据中（也就是在操作系统的堆上），指向其真正的页表。
///
/// 当 `PageTableTracker` 被 drop 时，会自动 drop `FrameTracker`，进而释放帧。
pub struct PageTableTracker(pub FrameTracker);

impl PageTableTracker {
    /// 将一个分配的帧清零，形成空的页表
    pub fn new(frame: FrameTracker) -> Self {
        let mut page_table = Self(frame);
        page_table.zero_init();
        page_table
    }
    /// 获取物理页号
    pub fn page_number(&self) -> PhysicalPageNumber {
        self.0.page_number()
    }
}
```

至此，我们完成了物理页中的页表。后面，我们将把内核中各个段做一个更精细的映射，把之前的那个粗糙的初始映射页表替换掉。