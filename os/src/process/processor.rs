//! 实现线程的调度和管理 [`Processor`]

use super::*;
use crate::data_structure::UnsafeWrapper;
use lazy_static::*;

lazy_static! {
    /// 全局的 [`Processor`]
    pub static ref PROCESSOR: UnsafeWrapper<Processor> = Default::default();
}

/// 线程调度和管理
#[derive(Default)]
pub struct Processor {
    /// 当前正在执行的线程
    current_thread: Option<Arc<Thread>>,
    /// 线程调度器，其中不包括正在执行的线程
    scheduler: Scheduler,
}

impl Processor {
    /// 第一次开始运行
    ///
    /// 从 `current_thread` 中取出 [`Context`]，然后直接调用 `interrupt.asm` 中的 `__restore`
    /// 来从 `Context` 中继续执行该线程。
    ///
    /// 注意调用 `run()` 的线程会就此步入虚无，不再被使用
    pub fn run(&mut self) -> ! {
        // interrupt.asm 中的标签
        extern "C" {
            fn __restore(context: *mut Context);
        }
        // 从 current_thread 中取出 Context
        let thread = self.current_thread.as_ref().unwrap().clone();
        let context = thread.run();
        // 因为这个线程（指的不是 thread，是运行 run 函数的线程）不会回来回收，所以手动 drop 掉 thread 的一个 Arc
        drop(thread);
        // 从此将没有回头
        unsafe {
            __restore(context);
        }
        unreachable!()
    }

    /// 在一个时钟中断时，替换掉 context
    pub fn tick(&mut self, context: &mut Context) -> *mut Context {
        // 暂停当前线程
        let current_thread = self.current_thread.take().unwrap();
        current_thread.park(*context);
        // 将其放回调度器
        self.scheduler.store(current_thread);

        // 取出一个线程
        let next_thread = self.scheduler.get();
        let context = next_thread.run();
        // 作为当前线程
        self.current_thread.replace(next_thread);
        context
    }

    /// 添加一个待执行的线程
    pub fn schedule_thread(&mut self, thread: Arc<Thread>) {
        // 如果 current_thread 为空就添加为 current_thread，否则丢给 scheduler
        if self.current_thread.is_none() {
            self.current_thread.replace(thread);
        } else {
            self.scheduler.store(thread);
        }
    }
}
