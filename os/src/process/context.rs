//! 保存一个线程的上下文信息 [`Context`]

use crate::memory::*;
use crate::interrupt::TrapFrame;

/// 线程切换过程的上下文
///
/// ### 为什么除了 `TrapFrame` 还要有 `Context`？
/// 虽然一般线程切换都发生在时钟中断时，但是两者是分开的事件，需要分别保存现场。
/// 具体而言，`TrapFrame` 保存线程被打断时的现场，而 `Context` 则是保存操作系统的现场。
///
/// > 中断、切换线程的处理流程
/// > 1. 产生中断
/// > 2. 操作系统的部分中断处理流程（保存 `TrapFrame`）
/// > 3. 操作系统调用线程切换函数（保存 `Context`）
/// > 4. 线程切换函数结束
/// > 5. 操作系统的剩余中断处理流程
/// > 6. 回到线程
/// >
/// > 也就是说，`TrapFrame` 保存现场是为了 1 6 步骤线程能够不受影响地执行；
/// > 而 `Context` 保存现场是为了 2 5 步骤操作系统能够正常执行。
///
/// 和中断的一个不同点在于，我们会主动调用『线程切换』函数。
/// 此时编译器已经在函数调用过程中保存了『调用者保存的寄存器』，而我们只需保存 `s0`-`s11`。
///
/// 除此之外，`Context` 中的 `ra` `sp` `satp` 共同描述了程序执行除寄存器数值之外的状态，也必须保存。
/// 其实还有 `sstatus`，但是在 2-5 步骤中，其值一定表示内核态，
/// 而线程的 `sstatus` 又会在第 6 步随 `TrapFrame` 一起恢复。所以 `Context` 是否保存它并没有太大意义。
///
/// ### 重要变量
/// - `ra` 是切换线程后开始执行的地址。
///   - 对于第一次启动的进程，`ra` 指向其第一条指令。
///   - 对于因中断而暂停的线程，则是指向该线程之前暂停时，调用 switch 的 ra。
/// 思考：在什么情况下，切换的两个线程具有相同的 `ra`？
#[repr(C)]
pub struct Context {
    /// `s0`-`s11` 寄存器
    s: [usize; 12],
    /// `ra` 寄存器
    ra: usize,
    /// `sp` 寄存器
    sp: usize,
    /// `satp` 寄存器
    satp: usize,
}

extern "C" {
    /// interrupt.asm 中恢复 TrapFrame 部分
    fn __restore();
}

impl Context {
    /// 切换线程
    #[naked]
    #[inline(never)]
    pub fn switch(current_context: &mut Context, target_context: &mut Context) {
        unsafe {
            llvm_asm!(include_str!("../asm/switch.asm") :::: "volatile");
        }
    }
}
