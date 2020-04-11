//! 中断模块
//! 
//! 

mod handler;
mod trap_frame;

/// 初始化中断相关的子模块
/// 
/// [`handler::init`]
pub fn init() {
    handler::init();
    println!("mod interrupt initialized");
}