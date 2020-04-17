//! 内存管理模块
//! 
//! 负责空间分配和虚拟地址映射

pub mod config;
pub mod address;
pub mod frame;
pub mod dynamic;

/// 初始化内存相关的子模块
/// 
/// - [`dynamic::init`]
pub fn init() {
    dynamic::init();
}