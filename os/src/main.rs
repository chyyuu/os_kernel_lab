#![no_std]
#![no_main]
#![feature(llvm_asm)]
#![feature(global_asm)]
#![feature(panic_info_message)]

//=====================SHARE PARTS============================

static mut CLOCKNUM:u64=0;
//======================= SUPERVISOR MODE =========================

//================== entry point ====================
global_asm!(include_str!("entry.asm"));

// ================ panic  handler ==================
use core::fmt::{self, Write};
use core::panic::PanicInfo;

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    if let Some(location) = info.location() {
        kprintln!(
            "Panicked at {}:{} {}",
            location.file(),
            location.line(),
            info.message().unwrap()
        );
    } else {
        kprintln!("Panicked: {}", info.message().unwrap());
    }
    shutdown()
}

// ================== SBI call ===============
const SBI_CONSOLE_PUTCHAR: usize = 1;
const SBI_SHUTDOWN: usize = 8;
const SBI_SET_TIMER: usize = 0;

pub fn console_putchar(c: usize) {
    sbicall(SBI_CONSOLE_PUTCHAR, [c, 0, 0]);
}

pub fn shutdown() -> ! {
    sbicall(SBI_SHUTDOWN, [0, 0, 0]);
    panic!("It should shutdown!");
}

pub fn set_timer(timer: usize) {
    sbicall(SBI_SET_TIMER, [timer, 0, 0]);
}

fn sbicall(id: usize, args: [usize; 3]) -> isize {
    let mut ret: isize;
    unsafe {
        llvm_asm!("ecall"
            : "={x10}" (ret)
            : "{x10}" (args[0]), "{x11}" (args[1]), "{x12}" (args[2]), "{x17}" (id)
            : "memory"
            : "volatile"
        );
    }
    ret
}

//===============kernel mode console ========================
struct Kstdout;

impl Write for Kstdout {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for c in s.chars() {
            console_putchar(c as usize);
        }
        Ok(())
    }
}

pub fn kconsole_print(args: fmt::Arguments) {
    Kstdout.write_fmt(args).unwrap();
}

#[macro_export]
macro_rules! kprint {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        kconsole_print(format_args!($fmt $(, $($arg)+)?));
    }
}

#[macro_export]
macro_rules! kprintln {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        kconsole_print(format_args!(concat!($fmt, "\n") $(, $($arg)+)?));
    }
}

//===============rv registers======================
use riscv::register::{
    mtvec::TrapMode,
    scause::{self, Trap, Interrupt},
    sstatus::{self, Sstatus, SPP},
    stval, stvec,sie, sepc,
    time,
};

//========= timer device =========================
pub fn enable_timer_interrupt() {
    unsafe {
        sie::set_stimer();
        sstatus::set_sie();
    }
}

const TICKS_PER_SEC: usize = 100;
const MSEC_PER_SEC: usize = 1000;
const CLOCK_FREQ: usize = 12500000;

pub fn get_time() -> usize {
    time::read()
}

pub fn get_time_ms() -> usize {
    time::read() / (CLOCK_FREQ / MSEC_PER_SEC)
}

pub fn set_next_trigger() {
    set_timer(get_time() + CLOCK_FREQ / TICKS_PER_SEC);
}

//================= for trap ===============================

// TrapContext needs 34*8 bytes
#[repr(C)]
pub struct TrapContext {
    pub x: [usize; 32],
    pub sstatus: Sstatus,
    pub sepc: usize,
}


// __alltraps & __restore functions
global_asm!(include_str!("trap.S"));

pub fn trap_init() {
    extern "C" {
        fn __alltraps(); //in trap.S
    }
    unsafe {
        stvec::write(__alltraps as usize, TrapMode::Direct);
    }
}


#[no_mangle]
pub fn trap_handler(cx: &mut TrapContext) -> &mut TrapContext {
    let scause = scause::read();
    let stval = stval::read();
    let sepc = sepc::read();

    match scause.cause() {
        // timer interrupt
        Trap::Interrupt(Interrupt::SupervisorTimer) => {
            kprintln!("clock");
            set_next_trigger();
            //unsafe {CLOCKNUM+=1;}
        }
        _ => {
            panic!(
                "Unsupported trap {:?}, stval = {:#x}, sepc = {:#x}",
                scause.cause(),
                stval, sepc
            );
        }
    }
    cx
}


//================ kernel main =============================
#[no_mangle]
#[link_section = ".text.entry"]
extern "C" fn rust_main() {
    kprintln!("Kernel: Hello, world!");
    trap_init();
    set_next_trigger();
    enable_timer_interrupt();
    loop{
        //unsafe {kprintln!("clock num is {}",CLOCKNUM);}
    };
}
