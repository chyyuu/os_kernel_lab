//! 内核栈 [`KernelStack`]
//!
//! 用户态的线程出现中断时，因为用户栈无法保证可用性，中断处理流程必须在内核栈上进行。
//! 所以我们创建一个公用的内核栈，即当发生中断时，会将 Context 写到内核栈顶。
//!
//! ### 用户线程和内核线程的区别
//! 注意到，在修改后的 `interrupt.asm` 中，添加了一些关于 `sscratch` 的判断。
//! - `sscratch` 存储什么？
//!   对于用户线程，`sscratch` 的值为内核栈地址；而对于内核线程，`sscratch` 的值为 0
//! - 为什么要用 `sscratch` 存储内核栈地址？
//!   为了保证中断处理流程有可用的栈，用户态发生中断时会将 `sscratch` 的值替换 `sp`。
//! - `sscratch` 是在哪里被保存的？
//!   调用 [`Thread::run()`] 时，将内核栈的地址写到了 `sp`，
//!   然后在 `__restore` 的流程中被存放至 `sscratch`。之所以没有直接写入，
//!   是为了和正常中断恢复的流程相兼容
//! - 内核线程的 `sscratch` 为 0，那么如何找到内核栈？
//!   内核线程发生中断时，检测到 `sscratch` 为 0，会直接使用当前线程的栈 `sp` 进行中断处理。
//!   也就是说我们编写的内核线程如果出现 bug 会导致整个操作系统崩盘
//! - 为什么内核线程要这么做？
//!   用户线程发生中断时就会进入内核态，而内核态可能发生中断的嵌套。此时，
//!   内核栈已经在中断处理流程中被使用，所以应当继续使用 `sp` 作为栈顶地址
//!
//! ### 用户线程 [`Context`] 的存放
//! > 1. 线程初始化时，一个 `Context` 放置在内核栈顶，`sp` 指向 `Context` 的位置
//! >   （即栈顶 - `size_of::<Context>()`）
//! > 2. 切换到线程，执行 `__restore` 时，将 `Context` 的数据恢复到寄存器中后，
//! >   会将 `Context` 出栈（即 `sp += size_of::<Context>()`），
//! >   然后保存 `sp` 至 `sscratch`（此时 `sscratch` 即为内核栈顶）
//! > 3. 发生中断时，将 `sscratch` 和 `sp` 互换，入栈一个 `Context` 并保存数据
//!
//! 容易发现，用户线程的 `Context` 一定保存在内核栈顶。因此，当线程需要运行时，
//! 从 [`Thread`] 中取出 `Context` 然后置于内核栈顶即可
//!
//! ### 内核线程 [`Context`] 的存放
//! > 1. 线程初始化时，一个 `Context` 放置在内核栈顶，`sp` 指向 `Context` 的位置
//! >   （即栈顶 - `size_of::<Context>()`）
//! > 2. 切换到线程，执行 `__restore` 时，将 `Context` 的数据恢复到寄存器中后，
//! >   内核栈便不再被内核线程所使用
//! > 3. 发生中断时，直接在 `sp` 上入栈一个 `Context`
//! > 4. 从中断恢复时，内核线程已经从 `Context` 中恢复了 `sp`，相当于自动释放了 `Context`
//! >   和中断处理流程所涉及的栈空间

use super::*;
use core::mem::size_of;
use lazy_static::*;

/// 内核栈
#[repr(align(16))]
#[repr(C)]
pub struct KernelStack([u8; KERNEL_STACK_SIZE]);

lazy_static! {
    /// 公用的内核栈
    pub static ref KERNEL_STACK: KernelStack = KernelStack([0; STACK_SIZE]);
}

impl KernelStack {
    /// 在栈顶加入 Context 并且返回 sp
    pub fn push_context(&self, context: Context) -> usize {
        let push_address = &self as *const _ as usize + STACK_SIZE - size_of::<Context>();
        unsafe {
            *(push_address as *mut Context) = context;
        }
        push_address
    }
}
