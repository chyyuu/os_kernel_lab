use crate::task::switch_to_next_task;

pub fn sys_exit(xstate: i32) -> ! {
    println!("[kernel] Application exited with code {}", xstate);
    //run_next_app()
    panic!("[kernel] first exit!");
}

pub fn sys_yield() -> isize {
    switch_to_next_task();
    0
}