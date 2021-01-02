global_asm!(include_str!("switch.S"));

extern "C" {
    pub fn __switch(current_task_cx: *const usize, next_task_cx: *const usize);
}
