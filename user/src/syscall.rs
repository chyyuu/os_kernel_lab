use super::{Stat, TimeVal};

pub const SYSCALL_OPENAT: usize = 56;
pub const SYSCALL_CLOSE: usize = 57;
pub const SYSCALL_READ: usize = 63;
pub const SYSCALL_WRITE: usize = 64;
pub const SYSCALL_UNLINKAT: usize = 35;
pub const SYSCALL_LINKAT: usize = 37;
pub const SYSCALL_FSTAT: usize = 80;
pub const SYSCALL_EXIT: usize = 93;
pub const SYSCALL_YIELD: usize = 124;
pub const SYSCALL_GETTIMEOFDAY: usize = 169;
pub const SYSCALL_GETPID: usize = 172;
pub const SYSCALL_FORK: usize = 220;
pub const SYSCALL_EXEC: usize = 221;
pub const SYSCALL_WAITPID: usize = 260;
pub const SYSCALL_SET_PRIORITY: usize = 140;
pub const SYSCALL_MUNMAP: usize = 215;
pub const SYSCALL_MMAP: usize = 222;
pub const SYSCALL_SPAWN: usize = 400;
pub const SYSCALL_MAIL_READ: usize = 401;
pub const SYSCALL_MAIL_WRITE: usize = 402;
pub const SYSCALL_DUP: usize = 24;
pub const SYSCALL_PIPE: usize = 59;

pub fn syscall(id: usize, args: [usize; 3]) -> isize {
    let mut ret: isize;
    unsafe {
        asm!(
            "ecall",
            inlateout("x10") args[0] => ret,
            in("x11") args[1],
            in("x12") args[2],
            in("x17") id
        );
    }
    ret
}

pub fn syscall6(id: usize, args: [usize; 6]) -> isize {
    let mut ret: isize;
    unsafe {
        asm!(
            "ecall",
            inlateout("x10") args[0] => ret,
            in("x11") args[1],
            in("x12") args[2],
            in("x13") args[3],
            in("x14") args[4],
            in("x15") args[5],
            in("x17") id
        );
    }
    ret
}

pub fn sys_openat(dirfd: usize, path: &str, flags: u32, mode: u32) -> isize {
    syscall6(
        SYSCALL_OPENAT,
        [
            dirfd,
            path.as_ptr() as usize,
            flags as usize,
            mode as usize,
            0,
            0,
        ],
    )
}

pub fn sys_close(fd: usize) -> isize {
    syscall(SYSCALL_CLOSE, [fd, 0, 0])
}

pub fn sys_read(fd: usize, buffer: &mut [u8]) -> isize {
    syscall(
        SYSCALL_READ,
        [fd, buffer.as_mut_ptr() as usize, buffer.len()],
    )
}

pub fn sys_write(fd: usize, buffer: &[u8]) -> isize {
    syscall(SYSCALL_WRITE, [fd, buffer.as_ptr() as usize, buffer.len()])
}

pub fn sys_linkat(
    old_dirfd: usize,
    old_path: &str,
    new_dirfd: usize,
    new_path: &str,
    flags: usize,
) -> isize {
    syscall6(
        SYSCALL_LINKAT,
        [
            old_dirfd,
            old_path.as_ptr() as usize,
            new_dirfd,
            new_path.as_ptr() as usize,
            flags,
            0,
        ],
    )
}

pub fn sys_unlinkat(dirfd: usize, path: &str, flags: usize) -> isize {
    syscall(SYSCALL_UNLINKAT, [dirfd, path.as_ptr() as usize, flags])
}

pub fn sys_fstat(fd: usize, st: &Stat) -> isize {
    syscall(SYSCALL_FSTAT, [fd, st as *const _ as usize, 0])
}

pub fn sys_mail_read(buffer: &mut [u8]) -> isize {
    syscall(
        SYSCALL_MAIL_READ,
        [buffer.as_ptr() as usize, buffer.len(), 0],
    )
}

pub fn sys_mail_write(pid: usize, buffer: &[u8]) -> isize {
    syscall(
        SYSCALL_MAIL_WRITE,
        [pid, buffer.as_ptr() as usize, buffer.len()],
    )
}

pub fn sys_exit(exit_code: i32) -> ! {
    syscall(SYSCALL_EXIT, [exit_code as usize, 0, 0]);
    panic!("sys_exit never returns!");
}

pub fn sys_yield() -> isize {
    syscall(SYSCALL_YIELD, [0, 0, 0])
}

pub fn sys_get_time(time: &TimeVal, tz: usize) -> isize {
    syscall(SYSCALL_GETTIMEOFDAY, [time as *const _ as usize, tz, 0])
}

pub fn sys_getpid() -> isize {
    syscall(SYSCALL_GETPID, [0, 0, 0])
}

pub fn sys_fork() -> isize {
    syscall(SYSCALL_FORK, [0, 0, 0])
}

pub fn sys_exec(path: &str) -> isize {
    syscall(SYSCALL_EXEC, [path.as_ptr() as usize, 0, 0])
}

pub fn sys_waitpid(pid: isize, xstatus: *mut i32) -> isize {
    syscall(SYSCALL_WAITPID, [pid as usize, xstatus as usize, 0])
}

pub fn sys_set_priority(prio: isize) -> isize {
    syscall(SYSCALL_SET_PRIORITY, [prio as usize, 0, 0])
}

pub fn sys_mmap(start: usize, len: usize, prot: usize) -> isize {
    syscall(SYSCALL_MMAP, [start, len, prot])
}

pub fn sys_munmap(start: usize, len: usize) -> isize {
    syscall(SYSCALL_MUNMAP, [start, len, 0])
}

pub fn sys_spawn(path: &str) -> isize {
    syscall(SYSCALL_SPAWN, [path.as_ptr() as usize, 0, 0])
}

pub fn sys_dup(fd: usize) -> isize {
    syscall(SYSCALL_DUP, [fd, 0, 0])
}

pub fn sys_pipe(pipe: &mut [usize]) -> isize {
    syscall(SYSCALL_PIPE, [pipe.as_mut_ptr() as usize, 0, 0])
}
