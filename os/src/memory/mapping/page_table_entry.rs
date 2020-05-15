//! 页表项 [`PageTableEntry`]
//!
//! # RISC-V 64 中的页表项结构
//! 每个页表项长度为 64 位，每个页面大小是 4KB，即每个页面能存下 2^9=512 个页表项。
//! 每一个页表存放 512 个页表项，说明每一级页表使用 9 位来标记 VPN。
//!
//! # RISC-V 64 两种页表组织方式：Sv39 和 Sv48
//! 64 位能够表示的空间大小太大了，因此现有的 64 位硬件实际上都不会支持 64 位的地址空间。
//!
//! RISC-V 64 现有两种地址长度：39 位和 48 位，其中 Sv39 的虚拟地址就包括三级页表和页内偏移。
//! `3 * 9 + 12 = 39`
//!
//! 我们使用 Sv39，Sv48 同理，只是它具有四级页表。

use crate::memory::address::*;
use bit_field::BitField;
use bitflags::*;

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
    /// 清除
    pub fn clear(&mut self) {
        self.0 = 0;
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
    /// 是否指向下一级（RWX 全为0）
    pub fn has_next_level(&self) -> bool {
        let flags = self.flags();
        !(flags.contains(Flags::READABLE)
            || flags.contains(Flags::WRITABLE)
            || flags.contains(Flags::EXECUTABLE))
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

macro_rules! implement_flags {
    ($field: ident, $name: ident, $quote: literal) => {
        impl Flags {
            #[doc = "返回 `Flags::"]
            #[doc = $quote]
            #[doc = "` 或 `Flags::empty()`"]
            pub fn $name(value: bool) -> Flags {
                if value {
                    Flags::$field
                } else {
                    Flags::empty()
                }
            }
        }
    };
}

implement_flags!{USER, user, "USER"}
implement_flags!{READABLE, readable, "READABLE"}
implement_flags!{WRITABLE, writable, "WRITABLE"}
implement_flags!{EXECUTABLE, executable, "EXECUTABLE"}