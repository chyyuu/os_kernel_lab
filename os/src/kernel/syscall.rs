//! 实现各种系统调用

use super::*;

pub const SYS_READ: usize = 63;
pub const SYS_WRITE: usize = 64;
pub const SYS_EXIT: usize = 93;

/// 系统调用在内核之内的返回值
pub(super) enum SyscallResult {
    /// 继续执行，带返回值
    Proceed(isize),
    /// 记录返回值，但暂存当前线程
    Park(isize),
    /// 丢弃当前 context，调度下一个线程继续执行
    Kill,
}

/// 系统调用的总入口
pub fn syscall_handler(context: &mut Context) -> *mut Context {
    // 无论如何处理，一定会跳过当前的 ecall 指令
    context.sepc += 4;

    let syscall_id = context.x[17];
    let args = [context.x[10], context.x[11], context.x[12]];

    let result = match syscall_id {
        SYS_READ => sys_read(args[0], args[1] as *mut u8, args[2]),
        SYS_WRITE => sys_write(args[0], args[1] as *mut u8, args[2]),
        SYS_EXIT => sys_exit(args[0]),
        _ => unimplemented!(),
    };

    match result {
        SyscallResult::Proceed(ret) => {
            // 将返回值放入 context 中
            context.x[10] = ret as usize;
            context
        }
        SyscallResult::Park(ret) => {
            // 将返回值放入 context 中
            context.x[10] = ret as usize;
            // 保存 context，准备下一个线程
            PROCESSOR.get().park_current_thread(context);
            PROCESSOR.get().prepare_next_thread()
        }
        SyscallResult::Kill => {
            // 终止，跳转到 PROCESSOR 调度的下一个线程
            PROCESSOR.get().kill_current_thread();
            PROCESSOR.get().prepare_next_thread()
        }
    }
}
