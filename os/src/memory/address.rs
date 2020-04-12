//! 定义地址类型和地址常量
//! 
//! 我们为虚拟地址和物理地址分别设立两个类型，利用编译器检查来防止混淆。

use lazy_static::*;

extern "C" {
    /// 由 `linker.ld` 指定的内核代码结束位置
    fn kernel_end();
}

lazy_static! {
    /// 可用内存空间开始地址，即内核代码结束的地址
    /// 
    /// 因为 Rust 语言限制，我们只能将其作为一个运行时求值的 static 变量，而不能作为 const
    pub static ref MEMORY_START_PADDR: Paddr = Paddr(kernel_end as usize);
}
/// 可用空间结束地址，由 QEMU 启动参数决定
pub const MEMORY_END_PADDR: Paddr = Paddr(0x88000000);

/// 虚拟地址
#[derive(Copy, Clone, Debug, Default)]
pub struct Vaddr(pub usize);

/// 物理地址
#[derive(Copy, Clone, Debug, Default)]
pub struct Paddr(pub usize);

/// 虚拟页号
#[derive(Copy, Clone, Debug, Default)]
pub struct VPN(pub usize);

/// 物理页号
#[derive(Copy, Clone, Debug, Default)]
pub struct PPN(pub usize);

impl From<Paddr> for PPN {
    fn from(paddr: Paddr) -> Self {
        Self(paddr.0 >> 12)
    }
}

impl<T: Into<usize>> core::ops::Add<T> for Vaddr {
    type Output = Self;
    fn add(self, other: T) -> Self::Output { Self(self.0 + other.into()) }
}
impl<T: Into<usize>> core::ops::Sub<T> for Vaddr {
    type Output = Self;
    fn sub(self, other: T) -> Self::Output { Self(self.0 - other.into()) }
}
impl<T: Into<usize>> core::ops::Add<T> for Paddr {
    type Output = Self;
    fn add(self, other: T) -> Self::Output { Self(self.0 + other.into()) }
}
impl<T: Into<usize>> core::ops::Sub<T> for Paddr {
    type Output = Self;
    fn sub(self, other: T) -> Self::Output { Self(self.0 - other.into()) }
}