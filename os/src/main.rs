#![no_std]
#![no_main]
#![feature(llvm_asm)]
#![feature(global_asm)]
#![feature(panic_info_message)]

//=====================SHARE PARTS============================
const STDOUT: usize = 1;
const SYSCALL_WRITE: usize = 64;
const SYSCALL_EXIT: usize = 93;

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
    scause::{self, Exception, Trap,Interrupt},
    sstatus::{self, Sstatus, SPP},
    stval, stvec,sie, sepc,
    time,
};

// =============== do syscall =========================
const FD_STDOUT: usize = 1;

pub fn do_write(fd: usize, buf: *const u8, len: usize) -> isize {
    match fd {
        FD_STDOUT => {
            let slice = unsafe { core::slice::from_raw_parts(buf, len) };
            let str = core::str::from_utf8(slice).unwrap();
            kprint!("{}", str);
            len as isize
        }
        _ => {
            panic!("Unsupported fd in sys_write!");
        }
    }
}

pub fn do_exit(exit_code: i32) -> ! {
    kprintln!("[kernel] Application exited with code {}", exit_code);
    panic!("System down");
}

pub fn do_syscall(syscall_id: usize, args: [usize; 3]) -> isize {
    match syscall_id {
        SYSCALL_WRITE => do_write(args[0], args[1] as *const u8, args[2]),
        SYSCALL_EXIT => do_exit(args[0] as i32),
        _ => panic!("Unsupported syscall_id: {}", syscall_id),
    }
}

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

impl TrapContext {
    pub fn set_sp(&mut self, sp: usize) {
        self.x[2] = sp;  //x2 reg is sp reg
    }
    pub fn app_init_context(entry: usize, sp: usize) -> Self {
        let mut sstatus = sstatus::read();
        sstatus.set_spp(SPP::User);
        let mut cx = Self {
            x: [0; 32],
            sstatus,
            sepc: entry,
        };
        cx.set_sp(sp);
        cx
    }
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
        Trap::Exception(Exception::UserEnvCall) => {
            cx.sepc += 4;
            cx.x[10] = do_syscall(cx.x[17], [cx.x[10], cx.x[11], cx.x[12]]) as usize;
        }
        // timer interrupt
        Trap::Interrupt(Interrupt::SupervisorTimer) => {
            //kprintln!("clock");
            set_next_trigger();
            unsafe {
                CLOCKNUM+=1;
                kprintln!("clock num is {}",CLOCKNUM);
            }
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

//================  run userapp ===================================
const USER_STACK_SIZE: usize = 4096 * 2;
const KERNEL_STACK_SIZE: usize = 4096 * 2;

#[repr(align(4096))]
struct KernelStack {
    data: [u8; KERNEL_STACK_SIZE],
}

#[repr(align(4096))]
struct UserStack {
    data: [u8; USER_STACK_SIZE],
}

static KERNEL_STACK: KernelStack = KernelStack {
    data: [0; KERNEL_STACK_SIZE],
};
static USER_STACK: UserStack = UserStack {
    data: [0; USER_STACK_SIZE],
};

impl KernelStack {
    fn get_sp(&self) -> usize {
        self.data.as_ptr() as usize + KERNEL_STACK_SIZE
    }
    pub fn push_context(&self, cx: TrapContext) -> &'static mut TrapContext {
        let cx_ptr = (self.get_sp() - core::mem::size_of::<TrapContext>()) as *mut TrapContext;
        unsafe {
            *cx_ptr = cx;
        }
        unsafe { cx_ptr.as_mut().unwrap() }
    }
}

impl UserStack {
    fn get_sp(&self) -> usize {
        self.data.as_ptr() as usize + USER_STACK_SIZE
    }
}

pub fn run_usrapp() -> ! {
    extern "C" {
        fn __restore(cx_addr: usize); //in trap.S
    }
    unsafe {
        __restore(KERNEL_STACK.push_context(TrapContext::app_init_context(
            usr_app_main as usize,
            USER_STACK.get_sp(),
        )) as *const _ as usize);
    }
    panic!("Unreachable in batch::run_current_app!");
}
//================ kernel main =============================
#[no_mangle]
#[link_section = ".text.entry"]
extern "C" fn rust_main() {
    kprintln!("Kernel: Hello, world!");
    trap_init();
    set_next_trigger();
    enable_timer_interrupt();
    //test2: uncomment below line
    //run_usrapp();
    //test2:=========================
    // test1: uncomment below code
    let mut i:u32=0;
    loop{
        while i <1000000 {
            i+=1;
        }
        i=0;
        unsafe {
            kprintln!("Kernel: Hello, world! {}", CLOCKNUM);
        }
    };
    //test1================================
}

//======================= USR MODE =========================
//========= usr mode syscall ==============
fn syscall(id: usize, args: [usize; 3]) -> isize {
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

pub fn sys_exit(xstate: i32) -> isize {
    syscall(SYSCALL_EXIT, [xstate as usize, 0, 0])
}

pub fn sys_write(fd: usize, buffer: &[u8]) -> isize {
    syscall(SYSCALL_WRITE, [fd, buffer.as_ptr() as usize, buffer.len()])
}

//=============== usr mode console ==================
struct Ustdout;

impl Write for Ustdout {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        sys_write(STDOUT, s.as_bytes());
        Ok(())
    }
}

pub fn uconsole_print(args: fmt::Arguments) {
    Ustdout.write_fmt(args).unwrap();
}

#[macro_export]
macro_rules! uprint {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        uconsole_print(format_args!($fmt $(, $($arg)+)?));
    }
}

#[macro_export]
macro_rules! uprintln {
    ($fmt: literal $(, $($arg: tt)+)?) => {
        uconsole_print(format_args!(concat!($fmt, "\n") $(, $($arg)+)?));
    }
}

//================ userapp main =============================
#[no_mangle]
#[link_section = ".text.entry"]
extern "C" fn usr_app_main() {

    uprintln!("Usrapp: Hello, world!");
    //test2: uncomment below lines
    // let mut i:u32=0;
    // loop{
    //     while i <1000000 {
    //         i+=1;
    //     }
    //     i=0;
    //     unsafe {
    //         uprintln!("Usrapp: Hello, world! {}", CLOCKNUM);
    //     }
    // };
    // sys_exit(9);
    //test2========================================
}
