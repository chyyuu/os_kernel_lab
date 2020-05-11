//! 线程 [`Thread`]

use super::*;
use core::mem::size_of;

/// 线程 ID 使用 `isize`，可以用负数表示错误
pub type ThreadID = isize;

static mut THREAD_COUNTER: ThreadID = 0;

/// 线程的信息
pub struct Thread {
    /// 线程 ID
    pub id: ThreadID,
    /// 线程的栈
    pub stack: Range<VirtualAddress>,
    /// 线程执行上下文
    ///
    /// 当且仅当线程被暂停执行时，`context` 为 `Some`
    pub context: Mutex<Option<Context>>,
    /// 所属的进程
    pub process: Arc<RwLock<Process>>,
}

impl Thread {
    /// 准备执行一个线程
    ///
    /// 激活对应进程的页表，并返回其 Context
    pub fn run(&self) -> *mut Context {
        // 激活页表
        self.process.read().memory_set.activate();
        // 取出 Context
        let parked_frame = self.context.lock().take().unwrap();

        if self.process.read().is_user {
            // 用户线程则将 Context 放至内核栈顶
            KERNEL_STACK.push_context(parked_frame)
        } else {
            // 内核线程则将 Context 放至 sp 下
            let context = (parked_frame.sp() - size_of::<Context>()) as *mut Context;
            unsafe { *context = parked_frame };
            context
        }
    }

    /// 发生时钟中断后暂停线程，保存状态
    pub fn park(&self, context: Context) {
        // 检查目前线程内的 context 应当为 None
        let mut slot = self.context.lock();
        assert!(slot.is_none());
        // 将 Context 保存到线程中
        slot.replace(context);
    }

    /// 创建一个线程
    pub fn new(
        process: Arc<RwLock<Process>>,
        entry_point: usize,
        arguments: Option<&[usize]>,
    ) -> MemoryResult<Arc<Thread>> {
        // 让所属进程分配并映射一段空间，作为线程的栈
        let stack = process
            .write()
            .alloc_page_range(STACK_SIZE, Flags::READABLE | Flags::WRITABLE)?;

        // 构建线程的 Context
        let context = Context::new(
            stack.end.into(),
            entry_point,
            arguments,
            process.read().is_user,
        );

        // 打包成线程
        let thread = Arc::new(Thread {
            id: unsafe {
                THREAD_COUNTER += 1;
                THREAD_COUNTER
            },
            stack,
            context: Mutex::new(Some(context)),
            process,
        });

        Ok(thread)
    }
}

/// 通过线程 ID 来判等
impl PartialEq for Thread {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

/// 通过线程 ID 来判等
///
/// 在 Rust 中，[`PartialEq`] trait 不要求任意对象 `a` 满足 `a == a`。
/// 将类型标注为 [`Eq`]，会沿用 `PartialEq` 中定义的 `eq()` 方法，
/// 同时声明对于任意对象 `a` 满足 `a == a`。
impl Eq for Thread {}

/// 打印线程除了父进程以外的信息
impl core::fmt::Debug for Thread {
    fn fmt(&self, formatter: &mut core::fmt::Formatter) -> core::fmt::Result {
        formatter
            .debug_struct("Thread")
            .field("thread_id", &self.id)
            .field("stack", &self.stack)
            .field("context", &self.context)
            .finish()
    }
}
