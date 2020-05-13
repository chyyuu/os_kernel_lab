## 实现内核重映射

在上文中，我们虽然构造了一个简单映射使得内核能够运行在虚拟空间上，但是这个映射是比较粗糙的。

我们知道一个程序通常含有下面几段：

- .text 段：存放代码，需要可读、可执行的，但不可写；
- .rodata 段：存放只读数据，顾名思义，需要可读，但不可写亦不可执行；
- .data 段：存放经过初始化的数据，需要可读、可写；
- .bss 段：存放零初始化的数据，需要可读、可写。

我们看到各个段之间的访问权限是不同的。在现在的映射下，我们甚至可以修改内核 .text 段的代码。因为我们通过一个标志位 `W` 为 1 的页表项完成映射。

因此，我们考虑对这些段分别进行重映射，使得他们的访问权限被正确设置。

这个需求可以抽象为一大段的内存（可能是很多个虚拟页）通过一个方式映射到很多个物理页上，同时这个内存段将会有一个统一的属性和进一步高层次的管理。

举个例子，在内核的代码段中 .bss 段可能不止会占用一个页面，而是很多页面，我们需要把全部的这些页面以线性的形式映射到一个位置。同时整个这些页面构成的内存段将会有统一的属性交由内核来管理。

下面，我们首先来封装内存段的概念。

### 内存段 Segment

正如上面说的，内存段是一篇连续的虚拟页范围，其中的每一页通过线性映射（直接偏移到一个物理页）或者分配（其中的每个虚拟页调用物理页分配器分配一个物理页）。线性映射出现在内核空间中；而为了支持每个用户进程看到的虚拟空间是一样的，我们不能全都用线性映射，所以基于页分配的方式会出现在用户这种情景下。如果你还是不明白，可以去翻看一下本章的「虚拟地址到物理地址」一个小节中非教学版 rCore 的映射图。

下面，我们用 enum 和 struct 来封装内存段映射的类型和内存段本身：

{% label %}os/src/memory/mapping/segment.rs{% endlabel %}
```rust
/// 映射的类型
#[derive(Debug)]
pub enum MapType {
    /// 线性映射，操作系统使用
    Linear,
    /// 按帧分配映射
    Framed,
}

/// 一个映射片段（对应旧 tutorial 的 `MemoryArea`）
#[derive(Debug)]
pub struct Segment {
    /// 映射类型
    pub map_type: MapType,
    /// 所映射的虚拟地址
    pub page_range: Range<VirtualPageNumber>,
    /// 权限标志
    pub flags: Flags,
}
```

后面，上层需要做的是把一个 Segment 中没有确定虚拟页到哪个物理页的全部虚拟页都申请一个物理页（或者说线性映射没有这样的虚拟页，而分配映射需要把每个虚拟页都申请一个对应的物理页）。

于是我们可以实现这样一个需要具体分配的迭代器（后面一并实现了一个方便的解引用）：

{% label %}os/src/memory/mapping/segment.rs{% endlabel %}
```rust
impl Segment {
    /// 遍历对应的物理地址（如果可能）
    pub fn iter_mapped(&self) -> Option<impl Iterator<Item = PhysicalPageNumber>> {
        match self.map_type {
            // 线性映射可以直接将虚拟地址转换
            MapType::Linear => Some(self.iter().map(PhysicalPageNumber::from)),
            // 按帧映射无法直接获得物理地址，需要分配
            MapType::Framed => None,
        }
    }
}

/// 方便访问 `page_range` 域中的方法
impl core::ops::Deref for Segment {
    type Target = Range<VirtualPageNumber>;
    fn deref(&self) -> &Self::Target {
        &self.page_range
    }
}
```

### Mapping

有了页表、内存段，我们对这两个进行组合和封装，借助其中对页表的操作实现对内存段的映射，或者也可以说这里的结构是对上一小节的页表的进一步的从单级到三级的封装，需要记录根页表和对其中申请的页表进行追踪来控制何时释放空间。

{% label %}os/src/memory/mapping/mapping.rs{% endlabel %}
```rust
#[derive(Default)]
/// 某个线程的内存映射关系
pub struct Mapping {
    /// 保存所有使用到的页表
    page_tables: Vec<PageTableTracker>,
    /// 根页表的物理页号
    root_ppn: PhysicalPageNumber,
}

impl Mapping {
    /// 创建一个有根节点的映射
    pub fn new() -> MemoryResult<Mapping> {
        let root_table = PageTableTracker::new(FRAME_ALLOCATOR.lock().alloc()?);
        let root_ppn = root_table.page_number();
        Ok(Mapping {
            page_tables: vec![root_table],
            root_ppn,
        })
    }
}
```

后面，实现对页表的查找，并利用该函数实现对虚拟页号到物理页号的映射：

{% label %}os/src/memory/mapping/mapping.rs: impl Mapping{% endlabel %}
```rust
/// 找到给定虚拟页号的三级页表项
///
/// 如果找不到对应的页表项，则会相应创建页表
pub fn find_entry(&mut self, vpn: VirtualPageNumber) -> MemoryResult<&mut PageTableEntry> {
    // 从根页表开始向下查询
    // 这里不用 self.page_tables[0] 避免后面产生 borrow-check 冲突（我太菜了）
    let root_table: &mut PageTable = PhysicalAddress::from(self.root_ppn).deref_kernel();
    let mut entry = &mut root_table.entries[vpn.levels()[0]];
    // println!("[{}] = {:x?}", vpn.levels()[0], entry);
    for vpn_slice in &vpn.levels()[1..] {
        if entry.is_empty() {
            // 如果页表不存在，则需要分配一个新的页表
            let new_table = PageTableTracker::new(FRAME_ALLOCATOR.lock().alloc()?);
            let new_ppn = new_table.page_number();
            // 将新页表的页号写入当前的页表项
            *entry = PageTableEntry::new(new_ppn, Flags::VALID);
            // 保存页表
            self.page_tables.push(new_table);
        }
        // 进入下一级页表（使用偏移量来访问物理地址）
        entry = &mut entry.get_next_table().entries[*vpn_slice];
    }
    // 此时 entry 位于第三级页表
    Ok(entry)
}

/// 为给定的虚拟 / 物理页号建立映射关系
fn map_one(
    &mut self,
    vpn: VirtualPageNumber,
    ppn: PhysicalPageNumber,
    flags: Flags,
) -> MemoryResult<()> {
    // 定位到页表项
    let entry = self.find_entry(vpn)?;
    assert!(entry.is_empty(), "virtual address is already mapped");
    // 页表项为空，则写入内容
    *entry = PageTableEntry::new(ppn, flags);
    Ok(())
}
```

有了 `map_one` 来实现一个虚拟页对物理页的映射，我们就可以一个连续的 Segment 的映射：

{% label %}os/src/memory/mapping/mapping.rs: impl Mapping{% endlabel %}
```rust
/// 加入一段映射，可能会相应地分配物理页面
///
/// - `init_data`
///     复制一段内存区域来初始化新的内存区域，其长度必须等于 `segment` 的大小。
///
///
/// 未被分配物理页面的虚拟页号暂时不会写入页表当中，它们会在发生 PageFault 后再建立页表项。
pub fn map(
    &mut self,
    segment: &Segment,
) -> MemoryResult<Vec<(VirtualPageNumber, FrameTracker)>> {
    // segment 可能可以内部做好映射
    if let Some(ppn_iter) = segment.iter_mapped() {
        // segment 可以提供映射，那么直接用它得到 vpn 和 ppn 的迭代器
        println!("map {:x?}", segment.page_range);
        for (vpn, ppn) in segment.iter().zip(ppn_iter) {
            self.map_one(vpn, ppn, segment.flags)?;
        }
        Ok(vec![])
    } else {
        // 需要再分配帧进行映射
        // 记录所有成功分配的页面映射
        let mut allocated_pairs = vec![];
        for vpn in segment.iter() {
            let frame: FrameTracker = FRAME_ALLOCATOR.lock().alloc()?;
            println!("map {:x?} -> {:x?}", vpn, frame.page_number());
            self.map_one(vpn, frame.page_number(), segment.flags)?;
            allocated_pairs.push((vpn, frame));
        }
        Ok(allocated_pairs)
    }
}
```

最后，我们实现一个函数实现页表的激活，也就是把 `satp` 寄存器更新并刷新 TLB：

{% label %}os/src/memory/mapping/mapping.rs: impl Mapping{% endlabel %}
```rust
/// 将当前的映射加载到 `satp` 寄存器
pub fn activate(&self) {
    // satp 低 27 位为页号，高 4 位为模式，8 表示 Sv39
    let new_satp = self.root_ppn.0 | (8 << 60);
    unsafe {
        // 将 new_satp 的值写到 satp 寄存器
        llvm_asm!("csrw satp, $0" :: "r"(new_satp) :: "volatile");
        // 刷新 TLB
        llvm_asm!("sfence.vma" :::: "volatile");
    }
}
```

### MemorySet

最后，我们需要把内核的每个段根据不同的属性写入上面的封装的 `Mapping` 中，并把它作为一个新的结构 `MemorySet` 给后面的线程的概念使用，这意味着：每个线程（到目前为止你可以大致理解为自己电脑中的同时工作的应用程序们）将会拥有一个 `MemorySet` 其中存的将会是「它看到的虚拟内存空间分成的内存段」和「这些段中包含的虚拟页到物理页的映射」：

{% label %}os/src/memory/mapping/memory_set.rs{% endlabel %}
```rust
/// 一个线程所有关于内存空间管理的信息
pub struct MemorySet {
    /// 维护页表和映射关系
    pub mapping: Mapping,
    /// 每个字段
    pub segments: Vec<Segment>,
}
```

到目前为止，我们还只有内核这个概念，所以我们只是实现一个内核的精细映射来代替开始的时候粗糙的权限管理（一并把页表激活实现）：

{% label %}os/src/memory/mapping/memory_set.rs{% endlabel %}
```rust
impl MemorySet {
    /// 创建内核重映射
    pub fn new_kernel() -> MemoryResult<MemorySet> {
        // 在 linker.ld 里面标记的各个字段的起始点，均为 4K 对齐
        extern "C" {
            fn text_start();
            fn rodata_start();
            fn data_start();
            fn bss_start();
        }

        // 建立字段
        let segments = vec![
            // .text 段，r-x
            Segment {
                map_type: MapType::Linear,
                page_range: Range::<VirtualAddress>::from(
                    (text_start as usize)..(rodata_start as usize),
                )
                .into(),
                flags: Flags::VALID | Flags::READABLE | Flags::EXECUTABLE,
            },
            // .rodata 段，r--
            Segment {
                map_type: MapType::Linear,
                page_range: Range::<VirtualAddress>::from(
                    (rodata_start as usize)..(data_start as usize),
                )
                .into(),
                flags: Flags::VALID | Flags::READABLE,
            },
            // .data 段，rw-
            Segment {
                map_type: MapType::Linear,
                page_range: Range::<VirtualAddress>::from(
                    (data_start as usize)..(bss_start as usize),
                )
                .into(),
                flags: Flags::VALID | Flags::READABLE | Flags::WRITABLE,
            },
            // .bss 段，rw-
            Segment {
                map_type: MapType::Linear,
                page_range: Range::from(
                    VirtualAddress::from(bss_start as usize)..*KERNEL_END_ADDRESS,
                ),
                flags: Flags::VALID | Flags::READABLE | Flags::WRITABLE,
            },
            // 剩余内存空间，rw-
            Segment {
                map_type: MapType::Linear,
                page_range: Range::from(
                    *KERNEL_END_ADDRESS..VirtualAddress::from(MEMORY_END_ADDRESS),
                ),
                flags: Flags::VALID | Flags::READABLE | Flags::WRITABLE,
            },
        ];
        let mut mapping = Mapping::new()?;
        // 准备保存所有新分配的物理页面
        let mut allocated_pairs: Box<dyn Iterator<Item = (VirtualPageNumber, FrameTracker)>> =
            Box::new(core::iter::empty());

        // 每个字段在页表中进行映射
        for segment in segments.iter() {
            let new_pairs = mapping.map(segment)?;
            // 同时将新分配的映射关系保存到 allocated_pairs 中
            allocated_pairs = Box::new(allocated_pairs.chain(new_pairs.into_iter()));
        }
        Ok(MemorySet { mapping, segments })
    }

    /// 替换 `satp` 以激活页表
    ///
    /// 如果当前页表就是自身，则不会替换，但仍然会刷新 TLB。
    pub fn activate(&self) {
        self.mapping.activate()
    }
}
```

到这里，我们完整实现了内核的重映射，最后的最后可以在主函数中测试一下：

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

    let remap = memory::mapping::MemorySet::new_kernel().unwrap();
    remap.activate();

    println!("kernel remapped");

    loop {}
}
```

在这里我们申请了了一个内核的重映射，然后对页表进行激活，后面运行了一句输出，虽然看起来没有什么不同，只是输出了一句话，但是需要注意到这句话所用的所有逻辑已经建立在了新的自己构建的页表上，而不是那个粗糙的 `boot_page_table` 了。`boot_page_table` 并非没有用，它为我们构建重映射提供了支持，但终究我们会用更好更精细的页表和映射代替了它，实现了更好的管理和安全性。

至此，我们实现了重映射，而在上面我们也只是用一个局部变量来调用了简单测试了这个映射，而实际上，后面我们会把全部运行的逻辑都封装为线程，每个线程将会有一个 `MemorySet` 并存在于一个线程的结构中而不是一个简单的局部变量。当线程销毁的时候，线程中全部使用的逻辑（包括页表所在的物理页和其他申请的物理页等）将会被之前设计的 Tracker 机制自动释放。

不得不说，用 Rust 写这些内容是痛苦的（可能后面一两个章节还会痛苦一段时间），但是为了充分发挥 Rust 的特性，这些挣扎是必要的，一旦我们铺平了这些基础设施，后面的流程会大大简化。对于这两章的内容我们也经历过大量讨论，也做了大量的设计性和教学性权衡，如果你阅读文档还是一头雾水，可以去完整的阅读代码和对应的注释并尝试运行。