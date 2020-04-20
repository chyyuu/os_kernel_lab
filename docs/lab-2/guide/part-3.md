## 物理内存管理

### 物理页帧

通常，我们在分配物理内存时并不是以字节为单位，而是以一**物理页帧(Frame)**，即连续的 4 KB 字节为单位分配。我们希望用物理页号（Physical Page Number，PPN）来代表一物理页，实际上代表物理地址范围在 $$[\text{PPN}\times 4\text{KB},(\text{PPN}+1)\times 4\text{KB})$$ 的一物理页。

不难看出，物理页号与物理页形成一一映射。为了能够使用物理页号这种表达方式，每个物理页的开头地址必须是 4 KB 的倍数。但这也给了我们一个方便：对于一个物理地址，其除以 4096（或者说右移 12 位）的商即为这个物理地址所在的物理页号。

同样的，我们还是用一个新的结构来封装一下物理页帧，一是为了和其他类型地址作区分；二是我们可以同时实现一些页帧和地址相互转换的功能。为了后面的方便，我们也把虚拟地址和虚拟页帧（概念还没有涉及，后面的指导会进一步讲解）一并实现出来：

{% label %}os/src/memory/address.rs{% endlabel %}
```rust
//! 定义地址类型和地址常量
//!
//! 我们为虚拟地址和物理地址分别设立两种类型，利用编译器检查来防止混淆。

use super::config::PAGE_SIZE;

/// 虚拟地址
#[derive(Copy, Clone, Debug, Default, Eq, PartialEq, Ord, PartialOrd)]
pub struct VirtualAddress(pub usize);

/// 物理地址
#[derive(Copy, Clone, Debug, Default, Eq, PartialEq, Ord, PartialOrd)]
pub struct PhysicalAddress(pub usize);

/// 虚拟页号
#[derive(Copy, Clone, Debug, Default, Eq, PartialEq, Ord, PartialOrd)]
pub struct VirtualPageNumber(pub usize);

/// 物理页号
#[derive(Copy, Clone, Debug, Default, Eq, PartialEq, Ord, PartialOrd)]
pub struct PhysicalPageNumber(pub usize);


// 以下是一大堆类型的相互转换、各种琐碎操作

macro_rules! implement_address_to_page_number {
    // 这里面的类型转换实现 [`From`] trait，会自动实现相反的 [`Into`] trait
    ($address_type: ty, $page_number_type: ty) => {
        impl From<$page_number_type> for $address_type {
            /// 从页号转换为地址
            fn from(page_number: $page_number_type) -> Self {
                Self(page_number.0 * PAGE_SIZE)
            }
        }
        impl From<$address_type> for $page_number_type {
            /// 从地址转换为页号，直接进行移位操作
            ///
            /// 不允许转换没有对齐的地址，这种情况应当使用 `floor()` 和 `ceil()`
            fn from(address: $address_type) -> Self {
                assert!(address.0 % PAGE_SIZE == 0);
                Self(address.0 / PAGE_SIZE)
            }
        }
        impl $page_number_type {
            /// 将地址转换为页号，向下取整
            pub const fn floor(address: $address_type) -> Self {
                Self(address.0 / PAGE_SIZE)
            }
            /// 将地址转换为页号，向上取整
            pub const fn ceil(address: $address_type) -> Self {
                Self(
                    address.0 / PAGE_SIZE +
                    (address.0 % PAGE_SIZE != 0) as usize
                )
            }
        }
        impl<T> From<*const T> for $address_type {
            /// 从指针转换为地址
            fn from(pointer: *const T) -> Self {
                Self(pointer as usize)
            }
        }
        impl<T> From<*mut T> for $address_type {
            /// 从指针转换为地址
            fn from(pointer: *mut T) -> Self {
                Self(pointer as usize)
            }
        }
        impl $address_type {
            /// 从地址转换为对象
            pub unsafe fn deref<T>(self) -> &'static mut T {
                assert!(self.valid());
                &mut *(self.0 as *mut T)
            }
        }
    }
}
implement_address_to_page_number!{PhysicalAddress, PhysicalPageNumber}
implement_address_to_page_number!{VirtualAddress, VirtualPageNumber}

/// 为各种仅包含一个 usize 的类型实现运算操作
macro_rules! implement_usize_operations {
...
}

implement_usize_operations!{PhysicalAddress}
implement_usize_operations!{VirtualAddress}
implement_usize_operations!{PhysicalPageNumber}
implement_usize_operations!{VirtualPageNumber}
```

同时，我们也需要在 `os/src/memory/config.rs` 中加入 `PAGE_SIZE` 的设置：

{% label %}os/src/memory/config.rs{% endlabel %}
```rust
/// 页 / 帧大小，必须是 2^n
pub const PAGE_SIZE: usize = 4096;
```

### 分配和回收

为了方便管理所有的物理页帧，我们需要实现一个分配器可以进行 `alloc` 和 `dealloc(AllocatedFrame)` 的操作，我们使用最简单的链表来做这件事情，首先先封装一下帧的相关概念。

<!-- TODO 代码 -->

这里我们为了节省空间，在物理帧还没有被分配的时候前 8 个字节用于链表的元信息的存储，而后面如果被分配了出去，整个 4096 字节都会被用来存储信息。

然后，我们实现用链表这种简单的数据结构来实现分配和删除。

<!-- TODO 代码 -->

最后，在把新写的模块加载进来，并在 main 函数中进行简单的测试：

<!-- TODO 代码 -->

可以看到类似这样的输出：

<!-- TODO 输出 -->