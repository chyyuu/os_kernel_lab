//! 实现线程的调度和管理 [`Processor`]

use super::*;
use lazy_static::*;

lazy_static! {
    pub static ref PROCESSOR: Processor = Processor::default();
}

#[derive(Default)]
pub struct Processor {
    current_thread: RwLock<Option<Arc<Thread>>>,
    scheduler: RwLock<Scheduler>,
}

impl Processor {
    /// 第一次开始运行
    ///
    /// 从 `current_thread` 中取出 [`TrapFrame`]，然后直接调用 `interrupt.asm` 中的 `__restore`
    /// 来从 `TrapFrame` 中继续执行该线程。
    ///
    /// 注意调用 `run()` 的线程会就此步入虚无，不再被使用
    pub fn run(&self) -> ! {
        // interrupt.asm 中的标签
        extern "C" {
            fn __restore(trap_frame: *mut TrapFrame);
        }
        // 从 current_thread 中取出 TrapFrame
        let thread = self.current_thread.write().as_ref().unwrap().clone();
        let trap_frame = thread.run();
        // 因为这个线程不会回来回收，所以手动 drop 掉线程的一个 Arc
        drop(thread);
        // 从此将没有回头
        unsafe {
            __restore(trap_frame);
        }
        unreachable!()
    }

    /// 在一个时钟中断时，替换掉 trap_frame
    pub fn tick(&self, trap_frame: &mut TrapFrame) -> *mut TrapFrame {
        // 暂停当前线程
        let current_thread = self.current_thread.write().take().unwrap();
        current_thread.park(*trap_frame);
        // 将其放回调度器
        self.scheduler.write().store(current_thread);

        // 取出一个线程
        let next_thread = self.scheduler.write().get();
        // 取出其 TrapFrame
        let trap_frame = next_thread.run();
        // 作为当前线程
        self.current_thread.write().replace(next_thread);
        trap_frame
    }

    /// 添加一个待执行的线程
    pub fn schedule_thread(&self, thread: Arc<Thread>) {
        if self.current_thread.read().is_none() {
            self.current_thread.write().replace(thread);
        } else {
            self.scheduler.write().store(thread);
        }
    }
}
