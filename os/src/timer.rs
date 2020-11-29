use riscv::register::time;
use crate::sbi::set_timer;
use crate::config::CPU_FREQ;

const TICKS_PER_SEC: usize = 100;

pub fn get_time() -> usize {
    time::read()
}

pub fn set_next_trigger() {
    set_timer(get_time() + CPU_FREQ / TICKS_PER_SEC);
}