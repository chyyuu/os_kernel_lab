//! 最高响应比优先算法的调度器 [`HrrnScheduler`]

use super::Scheduler;
use alloc::collections::LinkedList;

/// 将线程和调度信息打包
struct HrrnThread<ThreadType: Clone + Eq> {
    /// 进入线程池时，[`current_time`] 中的时间
    birth_time: usize,
    /// 被分配时间片的次数
    service_count: usize,
    /// 线程数据
    pub thread: ThreadType,
}

/// 采用 HRRN（最高响应比优先算法）的调度器
pub struct HrrnScheduler<ThreadType: Clone + Eq> {
    /// 当前时间，单位为 `get_next()` 调用次数
    current_time: usize,
    /// 带有调度信息的线程池
    pool: LinkedList<HrrnThread<ThreadType>>,
}

/// `Default` 创建一个空的调度器
impl<ThreadType: Clone + Eq> Default for HrrnScheduler<ThreadType> {
    fn default() -> Self {
        Self {
            current_time: 0,
            pool: LinkedList::new(),
        }
    }
}

impl<ThreadType: Clone + Eq> Scheduler<ThreadType> for HrrnScheduler<ThreadType> {
    fn add_thread<T>(&mut self, thread: ThreadType, _priority: T) {
        self.pool.push_back(HrrnThread {
            birth_time: self.current_time,
            service_count: 0,
            thread,
        })
    }
    fn get_next(&mut self) -> Option<ThreadType> {
        // 计时
        self.current_time += 1;

        // 遍历线程池，返回响应比最高者
        let current_time = self.current_time;   // borrow-check
        if let Some(best) = self.pool.iter_mut().max_by(|x, y| {
            ((current_time - x.birth_time) * y.service_count)
                .cmp(&((current_time - y.birth_time) * x.service_count))
        }) {
            best.service_count += 1;
            Some(best.thread.clone())
        } else {
            None
        }
    }
    fn remove_thread(&mut self, thread: ThreadType) {
        // 移除相应的线程并且确认恰移除一个线程
        let mut removed = self.pool.drain_filter(|t| t.thread == thread);
        assert!(removed.next().is_some() && removed.next().is_none());
    }
    fn set_priority<T>(&mut self, _thread: ThreadType, _priority: T) {}
}
