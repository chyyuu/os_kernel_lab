//! 线程调度算法

mod fifo_scheduler;
mod hrrn_scheduler;

/// 线程调度器
/// 
/// `ThreadType` 应为 `Arc<Thread>`
/// 
/// ### 使用方法
/// - 在每一个时间片结束后，调用 [`get_next()`] 来获取下一个时间片应当执行的线程。
///   这个线程可能是上一个时间片所执行的线程。
/// - 当一个线程结束时，需要调用 [`remove_thread()`] 来将其移除。这个方法必须在 
///   [`get_next()`] 之前调用。
pub trait Scheduler<ThreadType: Clone + Eq>: Default {
    /// 向线程池中添加一个线程
    fn add_thread<T>(&mut self, thread: ThreadType, priority: T);
    /// 获取下一个时间段应当执行的线程
    fn get_next(&mut self) -> Option<ThreadType>;
    /// 移除一个线程
    fn remove_thread(&mut self, thread: ThreadType);
    /// 设置线程的优先级
    fn set_priority<T>(&mut self, thread: ThreadType, priority: T);
}

pub use fifo_scheduler::FifoScheduler;
pub use hrrn_scheduler::HrrnScheduler;

pub type SchedulerImpl<T> = HrrnScheduler<T>;