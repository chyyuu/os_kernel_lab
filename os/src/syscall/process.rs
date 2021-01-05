use crate::task::{
    mark_current_suspended,
    mark_current_exited,
    run_next_task
};

pub fn sys_exit(exit_code: i32) -> ! {
    println!("[kernel] Application exited with code {}", exit_code);
    mark_current_exited();
    run_next_task();
    panic!("Unreachable in sys_exit!");
}

pub fn sys_yield() -> isize {
    mark_current_suspended();
    run_next_task();
    0
}