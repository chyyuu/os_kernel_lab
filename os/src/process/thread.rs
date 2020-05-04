//! 线程 [`Thread`]

use super::*;
use riscv::register::sstatus::{self, SPP::*};
use core::mem::size_of;

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
    /// 激活对应进程的页表，并返回其 TrapFrame
    pub fn run(&self) -> *mut TrapFrame {
        // 激活页表
        self.process.read().memory_set.activate();
        // 取出 TrapFrame
        let parked_frame = self.trap_frame.lock().take().unwrap();
        
        if self.process.read().is_user {
            // 用户线程则将 TrapFrame 放至内核栈顶
            KERNEL_STACK.push_trap_frame(parked_frame) as *mut TrapFrame
        } else {
            // 内核线程则将 TrapFrame 放至 sp 下
            let address = parked_frame.sp() - size_of::<TrapFrame>();
            let trap_frame = address.deref();
            *trap_frame = parked_frame;
            trap_frame
        }
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
