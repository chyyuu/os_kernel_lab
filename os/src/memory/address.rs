//! 定义地址类型和地址常量
//!
//! 我们为虚拟地址和物理地址分别设立两种类型，利用编译器检查来防止混淆。

use super::config::{KERNEL_MAP_OFFSET, PAGE_SIZE};
use bit_field::BitField;

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

impl VirtualAddress {
    /// 从虚拟地址取得某类型的 &mut 引用
    pub unsafe fn deref<T>(self) -> &'static mut T {
        assert!(self.0 > KERNEL_MAP_OFFSET);
        &mut *(self.0 as *mut T)
    }
    /// 线性映射为物理地址
    pub fn to_physical_linear(self) -> PhysicalAddress {
        PhysicalAddress(self.0 - KERNEL_MAP_OFFSET)
    }
}
/// 从指针转换为虚拟地址
impl<T> From<*const T> for VirtualAddress {
    fn from(pointer: *const T) -> Self {
        Self(pointer as usize)
    }
}
/// 从指针转换为虚拟地址
impl<T> From<*mut T> for VirtualAddress {
    fn from(pointer: *mut T) -> Self {
        Self(pointer as usize)
    }
}

impl PhysicalAddress {
    /// 从物理地址经过线性映射取得 &mut 引用
    pub unsafe fn deref_kernel<T>(self) -> &'static mut T {
        self.to_virtual_linear().deref()
    }
    /// 线性映射为虚拟地址
    pub fn to_virtual_linear(self) -> VirtualAddress {
        VirtualAddress(self.0 + KERNEL_MAP_OFFSET)
    }
}

impl VirtualPageNumber {
    /// 得到一、二、三级页号
    pub fn levels(self) -> [usize; 3] {
        [
            self.0.get_bits(30..39),
            self.0.get_bits(21..30),
            self.0.get_bits(12..21),
        ]
    }
    /// 线性映射为物理地址
    pub fn to_physical_linear(self) -> PhysicalPageNumber {
        PhysicalPageNumber(self.0 - KERNEL_MAP_OFFSET / PAGE_SIZE)
    }
}
impl PhysicalPageNumber {
    /// 线性映射为虚拟地址
    pub fn to_virtual_linear(self) -> VirtualPageNumber {
        VirtualPageNumber(self.0 + KERNEL_MAP_OFFSET / PAGE_SIZE)
    }
}

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
                Self(address.0 / PAGE_SIZE + (address.0 % PAGE_SIZE != 0) as usize)
            }
        }
    };
}
implement_address_to_page_number! {PhysicalAddress, PhysicalPageNumber}
implement_address_to_page_number! {VirtualAddress, VirtualPageNumber}

/// 为各种仅包含一个 usize 的类型实现运算操作
macro_rules! implement_usize_operations {
    ($type_name: ty) => {
        /// `+`
        impl core::ops::Add<usize> for $type_name {
            type Output = Self;
            fn add(self, other: usize) -> Self::Output {
                Self(self.0 + other)
            }
        }
        /// `+=`
        impl core::ops::AddAssign<usize> for $type_name {
            fn add_assign(&mut self, rhs: usize) {
                self.0 += rhs;
            }
        }
        /// `-`
        impl core::ops::Sub<usize> for $type_name {
            type Output = Self;
            fn sub(self, other: usize) -> Self::Output {
                Self(self.0 + other)
            }
        }
        /// `-=`
        impl core::ops::SubAssign<usize> for $type_name {
            fn sub_assign(&mut self, rhs: usize) {
                self.0 -= rhs;
            }
        }
        impl From<usize> for $type_name {
            fn from(value: usize) -> Self {
                Self(value)
            }
        }
        impl From<$type_name> for usize {
            fn from(value: $type_name) -> Self {
                value.0
            }
        }
        impl $type_name {
            /// 是否有效（0 为无效）
            fn valid(&self) -> bool {
                self.0 != 0
            }
        }
    };
}
implement_usize_operations! {PhysicalAddress}
implement_usize_operations! {VirtualAddress}
implement_usize_operations! {PhysicalPageNumber}
implement_usize_operations! {VirtualPageNumber}
