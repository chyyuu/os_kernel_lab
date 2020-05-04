//! 代替 std 库，实现 panic 和 abort 的功能

use crate::sbi::shutdown;
use core::panic::PanicInfo;

/// 打印 panic 的信息并 [`shutdown`]
///
/// ### `#[panic_handler]` 属性
/// 声明此函数是 panic 的回调
#[panic_handler]
fn panic_handler(info: &PanicInfo) -> ! {
    // `\x1b[??m` 是控制终端字符输出格式的指令，在支持的平台上可以改变文字颜色等等
    // 这里使用错误红
    // 需要全局开启 feature(panic_info_message) 才可以调用 .message() 函数
    // 参考：https://misc.flogisoft.com/bash/tip_colors_and_formatting
    if let Some(location) = info.location() {
        println!("\x1b[1;31m{}:{}: '{}'\x1b[0m", location.file(), location.line(), info.message().unwrap());
    } else {
        println!("\x1b[1;31mpanic: '{}'\x1b[0m", info.message().unwrap());
    }
    shutdown()
}

/// 终止程序
///
/// 调用 [`panic_handler`]
#[no_mangle]
extern "C" fn abort() -> ! {
    panic!("abort()")
}
