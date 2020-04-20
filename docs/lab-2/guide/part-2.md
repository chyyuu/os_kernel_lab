## 物理内存探测

### 物理内存的相关概念

我们知道，物理地址访问的通常是一片 DRAM，我们可以把它看成一个以字节为单位的大数组，通过物理地址找到对应的位置进行读写。但是，物理地址并不仅仅只能访问 DRAM，也可以用来访问其他的外设，因此你也可以认为 DRAM 也算是一种外设，物理地址则是一个对可以存储的介质的一种抽象。

而如果访问其他外设要使用不同的指令（如 x86 单独提供了 `in` 和 `out` 等指令来访问不同于内存的 IO 地址空间），会比较麻烦；于是，很多指令集架构（如 RISC-V、ARM 和 MIPS 等）通过 MMIO（Memory Mapped I/O）技术将外设映射到一段物理地址，这样我们访问其他外设就和访问物理内存一样了。

我们先不管那些外设，来看物理内存。

### 物理内存探测

操作系统怎样知道物理内存所在的那段物理地址呢？在 RISC-V 中，这个一般是由 Bootloader ，即 OpenSBI 来完成的。它来完成对于包括物理内存在内的各外设的扫描，将扫描结果以 DTB（Device Tree Blob）的格式保存在物理内存中的某个地方。随后 OpenSBI 会将其地址保存在 `a1` 寄存器中，给我们使用。

这个扫描结果描述了所有外设的信息，当中也包括 QEMU 模拟的 RISC-V Virt 计算机中的物理内存。

> **[info] QEMU 模拟的 RISC-V Virt 计算机中的物理内存**
>
> 通过查看 QEMU 代码中 [`hw/riscv/virt.c`](https://github.com/qemu/qemu/blob/master/hw/riscv/virt.c) 的 `virt_memmap[]` 的定义，可以了解到 QEMU 模拟的 RISC-V Virt 计算机的详细物理内存布局。可以看到，整个物理内存中有不少内存空洞（即含义为 unmapped 的地址空间），也有很多外设特定的地址空间，现在我们看不懂没有关系，后面会慢慢涉及到。目前只需关心最后一块含义为 DRAM 的地址空间，这就是 OS 将要管理的 128 MB 的内存空间。
>
> | 起始地址    | 终止地址     | 含义                                                  |
> | :--------: | :--------: | :---------------------------------------------------- |
> | 0x0        | 0x100      | QEMU VIRT_DEBUG                                       |
> | 0x100      | 0x1000     | unmapped                                              |
> | 0x1000     | 0x12000    | QEMU MROM                                             |
> | 0x12000    | 0x100000   | unmapped                                              |
> | 0x100000   | 0x101000   | QEMU VIRT_TEST                                        |
> | 0x101000   | 0x2000000  | unmapped                                              |
> | 0x2000000  | 0x2010000  | QEMU VIRT_CLINT                                       |
> | 0x2010000  | 0x3000000  | unmapped                                              |
> | 0x3000000  | 0x3010000  | QEMU VIRT_PCIE_PIO                                    |
> | 0x3010000  | 0xc000000  | unmapped                                              |
> | 0xc000000  | 0x10000000 | QEMU VIRT_PLIC                                        |
> | 0x10000000 | 0x10000100 | QEMU VIRT_UART0                                       |
> | 0x10000100 | 0x10001000 | unmapped                                              |
> | 0x10001000 | 0x10002000 | QEMU VIRT_VIRTIO                                      |
> | 0x10002000 | 0x20000000 | unmapped                                              |
> | 0x20000000 | 0x24000000 | QEMU VIRT_FLASH                                       |
> | 0x24000000 | 0x30000000 | unmapped                                              |
> | 0x30000000 | 0x40000000 | QEMU VIRT_PCIE_ECAM                                   |
> | 0x40000000 | 0x80000000 | QEMU VIRT_PCIE_MMIO                                   |
> | 0x80000000 | 0x88000000 | DRAM 缺省 128MB，大小可配置                              |

不过为了简单起见，我们并不打算自己去解析这个结果。因为我们知道，QEMU 规定的 DRAM 物理内存的起始物理地址为 0x80000000 。而在 QEMU 中，可以使用 `-m` 指定 RAM 的大小，默认是 128 MB 。因此，默认的 DRAM 物理内存地址范围就是 [0x80000000, 0x88000000)。

因为后面还会涉及到虚拟地址、物理页和虚拟页面的概念，为了进一步区分而不是简单的只是使用 `usize` 类型来存储，我们首先建立一个 `PhysicalAddress` 的类，然后对其实现一系列的 `usize` 的加、减和输出等等操作：

{% label %}os/src/memory/address.rs{% endlabel %}
```rust
/// 物理地址
#[derive(Copy, Clone, Debug, Default, Eq, PartialEq, Ord, PartialOrd)]
pub struct PhysicalAddress(pub usize);

/// 为各种仅包含一个 usize 的类型实现运算操作
macro_rules! implement_usize_operations {
    ($type_name: ty) => {
        /// `+`
        impl core::ops::Add<usize> for $type_name {
            type Output = Self;
            fn add(self, other: usize) -> Self::Output { Self(self.0 + other) }
        }
        /// `+=`
        impl core::ops::AddAssign<usize> for $type_name {
            fn add_assign(&mut self, rhs: usize) { self.0 += rhs; }
        }
        /// `-`
        impl core::ops::Sub<usize> for $type_name {
            type Output = Self;
            fn sub(self, other: usize) -> Self::Output { Self(self.0 + other) }
        }
        /// `-=`
        impl core::ops::SubAssign<usize> for $type_name {
            fn sub_assign(&mut self, rhs: usize) { self.0 -= rhs; }
        }
        impl core::ops::Deref for $type_name {
            type Target = usize;
            fn deref(&self) -> &Self::Target {
                &self.0
            }
        }
        impl $type_name {
            /// 是否有效（0 为无效）
            fn valid(&self) -> bool {
                self.0 != 0
            }
        }
        /// {} 输出
        impl core::fmt::Display for $type_name {
            fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
                write!(f, "{}(0x{:x})", stringify!($type_name), self.0)
            }
        }
    }
}

implement_usize_operations!(PhysicalAddress);
```

然后，我们直接将 DRAM 物理内存结束地址硬编码到内核中，同时因为我们操作系统本身也用了一部分空间，我们也记录下操作系统用到的地址结尾（即 linker script 中的 `kernel_end`）。

{% label %}os/src/memory/config.rs{% endlabel %}
```rust
use super::address::*;
use lazy_static::*;

/// 可以访问的内存区域起始地址
pub const MEMORY_START_ADDRESS: PhysicalAddress = PhysicalAddress(0x8000_0000);
/// 可以访问的内存区域结束地址
pub const MEMORY_END_ADDRESS: PhysicalAddress = PhysicalAddress(0x8800_0000);
lazy_static! {
    /// 内核代码结束的地址，即可以用来分配的内存起始地址
    ///
    /// 因为 Rust 语言限制，我们只能将其作为一个运行时求值的 static 变量，而不能作为 const
    pub static ref KERNEL_END_ADDRESS: PhysicalAddress = PhysicalAddress(kernel_end as usize);
}

extern "C" {
    /// 由 `linker.ld` 指定的内核代码结束位置
    ///
    /// 作为变量存在 [`KERNEL_END_ADDRESS`]
    fn kernel_end();
}
```

这里使用了 `lazy_static` 库，由于 Rust 语言的限制，我们能对编译时 `kernel_end` 做一个求值然后赋值到 `KERNEL_END_ADDRESS` 中；所以，`lazy_static!` 宏帮助我们在运行开始时自动完成这些求值工作。

最后，我们打包为新建 `os/src/memory/mod.rs`。

{% label %}os/src/memory/mod.rs{% endlabel %}
```rust
//! 内存管理模块
//!
//! 负责空间分配和虚拟地址映射

// 因为模块内包含许多基础设施类别，实现了许多以后可能会用到的函数，
// 所以在模块范围内不提示“未使用的函数”等警告
#![allow(dead_code)]

pub mod config;
pub mod address;
```

并在 `os/src/main.rs` 尝试输出。
{% label %}os/src/main.rs{% endlabel %}
```rust
...
mod memory;
...

/// Rust 的入口函数
///
/// 在 `_start` 为我们进行了一系列准备之后，这是第一个被调用的 Rust 函数
#[no_mangle]
pub extern "C" fn rust_main() -> ! {
    // 初始化各种模块
    interrupt::init();

    println!("{}", *memory::config::KERNEL_END_ADDRESS); // 注意这里的 KERNEL_END_ADDRESS 为 ref 类型，需要加 *

    loop{}
}
```

最后运行，可以看到成功显示了我们内核使用的结尾地址 `PhysicalAddress(0x8020b220)`；注意到这里，你的输出可能因为实现上的细节并不完全一样。