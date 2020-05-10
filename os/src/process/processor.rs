//! 实现线程的调度和管理 [`Processor`]

use super::*;
use algorithm::*;
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
    /// 线程调度器，记录所有线程
    scheduler: SchedulerImpl<Arc<Thread>>,
}

impl Processor {
    /// 获取一个当前线程的 `Arc` 引用
    pub fn current_thread(&self) -> Arc<Thread> {
        self.current_thread.as_ref().unwrap().clone()
    }

    /// 第一次开始运行
    ///
    /// 从 `current_thread` 中取出 [`Context`]，然后直接调用 `interrupt.asm` 中的 `__restore`
    /// 来从 `Context` 中继续执行该线程。
    ///
    /// 注意调用 `run()` 的线程会就此步入虚无，不再被使用
    pub fn run(&mut self) -> ! {
        // interrupt.asm 中的标签
        extern "C" {
            fn __restore(context: usize);
        }
        // 从 current_thread 中取出 Context
        let context = self.current_thread().run();
        // 从此将没有回头
        unsafe {
            __restore(context as usize);
        }
        unreachable!()
    }

    /// 在一个时钟中断时，替换掉 context
    pub fn tick(&mut self, context: &mut Context) -> *mut Context {
        // 向调度器询问下一个线程
        if let Some(next_thread) = self.scheduler.get_next() {
            if next_thread == self.current_thread() {
                // 没有更换线程，直接返回 Context
                context
            } else {
                // 准备下一个线程
                let next_context = next_thread.run();
                let current_thread = self.current_thread.replace(next_thread).unwrap();
                // 储存当前线程 Context
                current_thread.park(*context);
                // 返回下一个线程的 Context
                next_context
            }
        } else {
            panic!("all threads terminated, shutting down");
        }
    }

    /// 添加一个待执行的线程
    pub fn add_thread(&mut self, thread: Arc<Thread>) {
        // 如果 current_thread 为空就添加为 current_thread
        if self.current_thread.is_none() {
            self.current_thread.replace(thread.clone());
        }
        // 将线程加入调度器
        self.scheduler.add_thread(thread, 0);
    }

    /// 终止当前的线程
    pub fn kill_current_thread(&mut self) {
        // 从调度器中移除
        let thread = self.current_thread.take().unwrap();
        self.scheduler.remove_thread(thread);
        // 向调度器询问下一个线程，替换 current_thread
        if let Some(next_thread) = self.scheduler.get_next() {
            self.current_thread.replace(next_thread);
        } else {
            panic!("all threads terminated, shutting down");
        }
    }
}
