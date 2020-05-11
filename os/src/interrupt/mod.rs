//! 中断模块
//!
//!

#![allow(unused)]

mod context;
mod handler;
mod timer;

pub use context::Context;

/// 初始化中断相关的子模块
///
/// - [`handler::init`]
/// - [`timer::init`]
pub fn init() {
    handler::init();
    timer::init();
    println!("mod interrupt initialized");
}
