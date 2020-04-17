//! 定义地址类型和地址常量
//! 
//! 我们为虚拟地址和物理地址分别设立两种类型，利用编译器检查来防止混淆。

#![allow(dead_code)]

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
    }
}
implement_address_to_page_number!{PhysicalAddress, PhysicalPageNumber}
implement_address_to_page_number!{VirtualAddress, VirtualPageNumber}

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
    }
}
implement_usize_operations!{PhysicalAddress}
implement_usize_operations!{VirtualAddress}
implement_usize_operations!{PhysicalPageNumber}
implement_usize_operations!{VirtualPageNumber}
