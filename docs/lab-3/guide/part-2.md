## 修改内核

之前的内核实现并未使能页表机制，实际上内核是直接在物理地址空间上运行的。这样虽然比较简单，但是为了后续能够支持多个用户进程能够在内核中并发运行，满足隔离等性质，我们要先运用学过的页表知识，把内核的运行环境从物理地址空间转移到虚拟地址空间，为之后的功能打好铺垫。

更具体的，我们现在想将内核代码放在虚拟地址空间中以 0xffffffff80200000 开头的一段高地址空间中。这意味我们原来放在 0x80200000 的全部内核结构被平移到了 0xffffffff80200000 的地址上，这意味着我们把虚拟地址减去偏移量 0xffffffff00000000 就得到了原来的物理地址。当然，这种线性平移并不是唯一的映射方式，但是至少现在，内核的全部数据所在的虚拟空间和物理空间是这样的线性映射。

首先，和上一章类似，我们先对虚拟地址和虚拟页号这两个类进行了封装，同时也支持了一些诸如 `VirtualAddress::from(Physical)` 的转换 trait（即一些加减偏移量等操作），这部分实现更偏向于 Rust 语法，这里不再赘述实现方法，想去了解实现时可以参考 `os/src/memory/address.rs`。

后面，我们把原来的 linker script 和之前在物理内存管理上的一些参数修改一下。

{% label %}os/src/linker/linker.ld{% endlabel %}
```clike
/* Linker Script 语法可以参见：http://www.scoberlin.de/content/media/http/informatik/gcc_docs/ld_3.html */

/* 目标架构 */
OUTPUT_ARCH(riscv)

/* 执行入口 */
ENTRY(_start)

/* 数据存放起始地址 */
BASE_ADDRESS = 0xffffffff80200000; /* 修改为虚拟地址 */

SECTIONS
{
    /* . 表示当前地址（location counter） */
    . = BASE_ADDRESS;

    /* start 符号表示全部的开始位置 */
    kernel_start = .;

    /* 加入对齐 */
    . = ALIGN(4K);
    text_start = .;

    /* .text 字段 */
    .text : {
        /* 把 entry 函数放在最前面 */
        *(.text.entry)
        /* 要链接的文件的 .text 字段集中放在这里 */
        *(.text .text.*)
    }

    /* 加入对齐 */
    . = ALIGN(4K);
    rodata_start = .;

    /* .rodata 字段 */
    .rodata : {
        /* 要链接的文件的 .rodata 字段集中放在这里 */
        *(.rodata .rodata.*)
    }

    /* 加入对齐 */
    . = ALIGN(4K);
    data_start = .;

    /* .data 字段 */
    .data : {
        /* 要链接的文件的 .data 字段集中放在这里 */
        *(.data .data.*)
    }

    /* 加入对齐 */
    . = ALIGN(4K);
    bss_start = .;

    /* .bss 字段 */
    .bss : {
        /* 要链接的文件的 .bss 字段集中放在这里 */
        *(.bss .bss.*)
    }

    /* 加入对齐 */
    . = ALIGN(4K);
    boot_stack_start = .;

    /* stack 字段 */
    .stack : {
        /* 把 bss.stack 字段所申请的空间放在这里作为启动时的栈空间 */
        *(.bss.stack)
    }

    /* 结束地址 */
    kernel_end = .;
}
```

首先，对于 linker script，我们把放置的基地址修改为了虚拟地址，另外还有一些修改是我们把每个数据段都对齐到了 4KB，一个 4KB 的虚拟页中不会包含两个段，这意味着这个页的属性是可以确定的。举个例子，如果不对齐的话，只读的 .rodata 和 .data 段可能放在一个页中，但是页表中需要写上诸如是否可写的属性，这时候就必须分开才可以标注属性。

对应修改 `os/src/memory/config.rs` 中的 `KERNEL_END_ADDRESS` 修改为虚拟地址并加入偏移量：

{% label %}os/src/memory/config.rs{% endlabel %}
```rust
lazy_static! {
    /// 内核代码结束的地址，即可以用来分配的内存起始地址
    /// 
    /// 因为 Rust 语言限制，我们只能将其作为一个运行时求值的 static 变量，而不能作为 const
    pub static ref KERNEL_END_ADDRESS: VirtualAddress = VirtualAddress(kernel_end as usize); 
}

/// 内核使用线性映射的偏移量
pub const KERNEL_MAP_OFFSET: usize = 0xffff_ffff_0000_0000;
```

之后是 `FrameAllocator` 确定第一个可用的物理页的位置也需要修改：
```rust
impl FrameAllocator {
    /// 创建对象，其中 \[[`BEGIN_VPN`], [`END_VPN`]) 区间内的帧在其空闲列表中
    pub fn new() -> Self {
        // 定位到第一个可用的物理帧
        // 因为 KERNEL_END_ADDRESS 现在成了虚拟地址，所以需要先转换为物理地址再向上取整为第一个可用的物理页
        let first_frame_ppn = PhysicalPageNumber::ceil(PhysicalAddress::from(*KERNEL_END_ADDRESS));
        let first_frame_address = PhysicalAddress::from(first_frame_ppn);
        FrameAllocator {
            free_frame_list: vec![(first_frame_address, END_PPN - first_frame_ppn)],
        }
    }
    ...
}
```

最后一步，我们需要告诉 RISC-V CPU 我们做了这些修改，也就是需要完成一个从物理地址访存模式到虚拟访存模式的转换，同时这也意味着，我们要写一个简单的页表，完成这个线性映射：

{% label %}os/src/asm/entry.asm{% endlabel %}
```assembly
# 操作系统启动时所需的指令以及字段
#
# 我们在 linker.ld 中将程序入口设置为了 _start，因此在这里我们将填充这个标签
# 它将会执行一些必要操作，然后跳转至我们用 rust 编写的入口函数
#
# 关于 RISC-V 下的汇编语言，可以参考 https://rv8.io/asm.html
# %hi 表示取 [12,32) 位，%lo 表示取 [0,12) 位

    .section .text.entry
    .globl _start
# 目前 _start 的功能：将预留的栈空间写入 $sp，然后跳转至 rust_main
_start:
    # 计算 boot_page_table 的物理页号
    lui t0, %hi(boot_page_table)
    li t1, 0xffffffff00000000
    sub t0, t0, t1
    srli t0, t0, 12
    # 8 << 60 是 satp 中使用 Sv39 模式的记号
    li t1, (8 << 60)
    or t0, t0, t1
    # 写入 satp 并更新 TLB
    csrw satp, t0
    sfence.vma

    # 加载栈地址
    lui sp, %hi(bootstacktop)
    addi sp, sp, %lo(bootstacktop)
    # 跳转至 rust_main
    lui t0, %hi(rust_main)
    addi t0, t0, %lo(rust_main)
    jr t0

    # 回忆：bss 段是 ELF 文件中只记录长度，而全部初始化为 0 的一段内存空间
    # 这里声明字段 .bss.stack 作为操作系统启动时的栈
    .section .bss.stack
    .global bootstack
bootstack:
    .space 4096 * 4
    .global bootstacktop
bootstacktop:
    # 栈结尾

    # 初始内核映射所用的页表
    .section .data
    .align 12
boot_page_table:
    .quad 0
    .quad 0
    # 第 2 项：0x8000_0000 -> 0x8000_0000，0xcf 表示 VRWXAD 均为 1
    .quad (0x80000 << 10) | 0xcf
    .zero 507 * 8
    # 第 510 项：0xffff_ffff_8000_0000 -> 0x8000_0000，0xcf 表示 VRWXAD 均为 1
    .quad (0x80000 << 10) | 0xcf
    .quad 0
```

回顾一下，当 OpenSBI 启动完成之后，我们面对的是一个怎样的局面：
- 物理内存状态中 OpenSBI 代码放在 [0x80000000,0x80200000) 中，内核代码放在以 0x80200000 开头的一块连续物理内存中；
- CPU 状态：处于 S Mode ，寄存器 `satp` 的 `MODE` 字段被设置为 Bare 模式，即无论取指还是访存我们通过物理地址直接访问物理内存。PC 即为 0x80200000 指向内核的第一条指令；
- 栈指针寄存器 `sp` 还没有初始化，还没有指向 `bootstacktop`；
- 代码中 `bootstacktop` 等符号的地址都是虚拟地址（高地址）。

而我们需要做的就是，把 CPU 的访问模式改为 Sv39，这里需要做的就是把一个页表的物理页号和 Sv39 模式写入 `satp` 寄存器，然后刷新 TLB。

我们先使用一种最简单的页表构造方法，还记得上一节中所讲的大页吗？那时我们提到，将一个三级页表项的标志位 `R,W,X` 不设为全 0，可以将它变为表示 1GB 的一个大页。

那么，页表里面需要放什么数据呢？第二个 `.quad` （表中第 510 项，510 的二进制是要索引虚拟地址的 $$VPN_3$$）显然是从 0xffffffff80000000 到 0x80000000 这样的线性映射，同时 `0xcf` 表示了 `VRWXAD` 均为 1 的属性。

观察一下，除了上面这个映射，我们的 `boot_page_table` 里面为什么还有一个从 0x80000000 到 0x80000000 的映射？

{% reveal %}
> 这是因为，在跳转到 `rust_main` 之前（即 `jr t0`）之前，PC 的值都还是 0x802xxxxx 这样的地址，即使是写入了 `satp` 寄存器，但是 PC 的地址不会变。为了执行这段中间的尴尬的代码，我们在页表里面也需要加入这段代码的地址的映射。
> 
> 那为什么跳转之后就没有问题了呢？这是因为 `rust_main` 这个符号本身是高虚拟地址（这点在 linker script 里面已经体现了）。
> 
> 为什么我把这个映射删了，代码还是可以运行？因为 QEMU 有指令缓存，实际上这样的删去的写法是错误的。
> 
> 这个尴尬的映射会对后面产生错误的影响吗？不会，因为在后面，我们将使用 Rust 而不是汇编把新的页表加载到 `satp` 里面，这个页表只是启动时的一个简单页表，或者我们可以叫它“内核初始映射”，后面我们会加入更细致的映射，把不同的段根据属性放在不同的页面里面。
{% endreveal %}

刷新之后，我们加载完栈底值，就可以跳转到 Rust 编写的函数中了。至此，我可以在主函数中做些简单的输出，我们重新编译（cargo 不会感知 linker script 的变化，可能需要 `cargo clean`）并运行，正确的结果应该是我们可以看到这些输出，虽然这和上一个章节的结果看上去没什么两样，但是现在内核的运行已经在虚拟地址空间了。