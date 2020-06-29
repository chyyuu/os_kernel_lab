//! 驱动模块
//!
//! 负责驱动管理

use crate::memory::{PhysicalAddress, VirtualAddress};

pub mod block;
pub mod bus;
pub mod device_tree;
pub mod driver;

/// 从设备树的物理地址来获取全部设备信息并初始化
pub fn init(dtb_pa: PhysicalAddress) {
    let dtb_va = VirtualAddress::from(dtb_pa);
    device_tree::init(dtb_va);
    println!("mod driver initialized")
}
