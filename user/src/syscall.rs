const SYSCALL_WRITE: usize = 64;
const SYSCALL_EXIT: usize = 93;

fn syscall(id: usize, arg0: usize, arg1: usize, arg2: usize) -> isize {
    let mut ret;
    unsafe {
        llvm_asm!("ecall"
            : "={x10}" (ret)
            : "{x10}" (arg0), "{x11}" (arg1), "{x12}" (arg2), "{x17}" (id)
            : "memory"      // 如果汇编可能改变内存，则需要加入 memory 选项
            : "volatile"); // 防止编译器做激进的优化（如调换指令顺序等破坏 SBI 调用行为的优化）
    }
    ret
}

pub fn sys_write(c: usize) -> isize {
    syscall(SYSCALL_WRITE, c, 0, 0)
}

pub fn sys_exit(code: isize) -> ! {
    syscall(SYSCALL_EXIT, code as usize, 0, 0);
    unreachable!()
}