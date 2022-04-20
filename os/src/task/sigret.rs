use core::arch::global_asm;

global_asm!(include_str!("sigret.S"));

extern "C" {
    pub fn start_sigret();
    pub fn end_sigret();
}
