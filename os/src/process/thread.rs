//! 线程 [`Thread`]

use super::*;
use crate::memory::*;
use alloc::sync::Arc;
use riscv::register::sstatus::{self, SPP::*};
use spin::{Mutex, RwLock};

/// 线程的信息
pub struct Thread {
    /// 线程的栈
    pub stack: Stack,
    /// 线程执行上下文
    ///
    /// 当且仅当线程被暂停执行时，`trap_frame` 为 `Some`
    pub trap_frame: Mutex<Option<TrapFrame>>,
    /// 所属的进程
    pub process: Arc<RwLock<Process>>,
}

impl Thread {
    /// 执行一个线程
    ///
    /// 激活对应进程的页表，然后从线程的 TrapFrame 中恢复现场开始执行
    ///
    /// 注意到，程序的控制流会进入目标线程，而不会返回。
    /// 需要等到下一次中断，线程才会被暂停，控制流再回到 `handle_interrupt`。
    pub fn run(&self) -> ! {
        // 激活页表
        self.process.read().memory_set.activate();
        // 取出 trap_frame 并放到内核栈顶
        let trap_frame = self.trap_frame.lock().take().unwrap();
        let sp = KERNEL_STACK.push_trap_frame(trap_frame);
        unsafe {
            // 修改 sp
            llvm_asm!("mv sp, $0" :: "r"(sp) :: "volatile");
            // 进入 interrupt.asm 中的恢复中断流程
            llvm_asm!("j __restore" :::: "volatile");
        }
        // 程序不会返回到这里
        unreachable!()
    }

    /// 发生时钟中断后暂停线程，保存状态
    pub fn park(&self, trap_frame: TrapFrame) {
        // 检查目前线程内的 trap_frame 应当为 None
        let mut slot = self.trap_frame.lock();
        assert!(slot.is_none());
        // 将 TrapFrame 保存到线程中
        slot.replace(trap_frame);
    }

    /// 创建一个线程
    pub fn new(
        process: Arc<RwLock<Process>>,
        entry_point: usize,
        arguments: Option<&[usize]>,
    ) -> MemoryResult<Arc<Thread>> {
        // 从地址空间中找一段空间存放栈
        let mut stack_range = Range::<VirtualAddress>::from(0..STACK_SIZE);
        while process.read().memory_set.overlap_with(stack_range.into()) {
            stack_range.start += STACK_SIZE;
            stack_range.end += STACK_SIZE;
        }
        // 构建栈，从进程中继承特权信息
        let stack = Stack::new(stack_range, process.read().is_user);
        // 映射这段空间
        process
            .write()
            .memory_set
            .add_segment(stack.get_segment())?;

        // 构建线程的 TrapFrame
        let trap_frame = TrapFrame {
            x: {
                let mut x = [0usize; 32];
                // 栈顶为新创建的栈顶
                x[2] = stack.top().into();
                // 写入参数，这里没有考虑一些特殊情况，比如参数大于 8 个或 struct 铺开等
                if let Some(args) = arguments {
                    x[10..(10 + args.len())].copy_from_slice(args);
                }
                x
            },
            // sstatus 设置为，在 sret 之后，开启中断
            sstatus: {
                let mut sstatus = sstatus::read();
                if process.read().is_user {
                    sstatus.set_spp(User);
                } else {
                    sstatus.set_spp(Supervisor);
                }
                // 这样设置 SPIE 和 SIE 位，使得替换 sstatus 后关闭中断，
                // 而在 sret 到用户线程时开启中断。详见 SPIE 和 SIE 的定义
                sstatus.set_spie(true);
                sstatus.set_sie(false);
                sstatus
            },
            // sret 后进入 entry_point
            sepc: entry_point,
        };

        // 打包成线程
        let thread = Arc::new(Thread {
            stack,
            trap_frame: Mutex::new(Some(trap_frame)),
            process: process.clone(),
        });
        process.write().push_thread(thread.clone());
        Ok(thread)
    }
}
