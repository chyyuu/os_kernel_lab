//! 进程相关的内核功能

use super::*;

pub(super) fn sys_exit(code: usize) -> SyscallResult {
    println!(
        "Thread {} exit with code {}",
        PROCESSOR.get().current_thread().id,
        code
    );
    SyscallResult::Kill
}
