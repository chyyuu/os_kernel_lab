//! 每个线程的栈 [`Stack`] 以及内核栈 [`KernelStack`]

use super::*;
use crate::memory::*;
use core::mem::size_of;
use lazy_static::*;

/// 栈是一片内存区域，其空间分配在 `Mapping` 中完成
pub struct Stack {
    range: Range<VirtualAddress>,
    is_user: bool,
}

impl Stack {
    pub fn new(range: Range<VirtualAddress>, is_user: bool) -> Self {
        Self { range, is_user }
    }

    /// 生成对应的 [`Segment`]，其权限为 rw-
    pub fn get_segment(&self) -> Segment {
        Segment {
            map_type: MapType::Framed,
            page_range: Range::from(
                VirtualPageNumber::floor(self.range.start)..VirtualPageNumber::ceil(self.range.end),
            ),
            flags: if self.is_user {
                Flags::READABLE | Flags::WRITABLE | Flags::USER
            } else {
                Flags::READABLE | Flags::WRITABLE
            },
        }
    }

    /// 返回栈顶地址
    pub fn top(&self) -> VirtualAddress {
        self.range.end
    }
}

/// 内核栈
///
/// 用户态的线程出现中断时，因为用户栈无法保证可用性，中断处理流程必须在内核栈上进行。
/// 所以我们创建一个公用的内核栈，即当发生中断时，会将 TrapFrame 写到内核栈顶。
///
/// ### 用户线程和内核线程的区别
/// 注意到，在修改后的 `interrupt.asm` 中，添加了一些关于 `sscratch` 的判断。
/// - `sscratch` 存储什么？
///   对于用户线程，`sscratch` 的值为内核栈地址；而对于内核线程，`sscratch` 的值为 0
/// - 为什么要用 `sscratch` 存储内核栈地址？
///   为了保证中断处理流程有可用的栈，用户态发生中断时会将 `sscratch` 的值替换 `sp`。
/// - `sscratch` 是在哪里被保存的？
///   调用 [`Thread::run()`] 时，将内核栈的地址写到了 `sp`，
///   然后在 `__restore` 的流程中被存放至 `sscratch`。之所以没有直接写入，
///   是为了和正常中断恢复的流程相兼容
/// - 内核线程的 `sscratch` 为 0，那么如何找到内核栈？
///   内核线程发生中断时，检测到 `sscratch` 为 0，会直接使用当前线程的栈 `sp` 进行中断处理。
///   也就是说我们编写的内核线程如果出现 bug 会导致整个操作系统崩盘
/// - 为什么内核线程要这么做？
///   用户线程发生中断时就会进入内核态，而内核态可能发生中断的嵌套。此时，
///   内核栈已经在中断处理流程中被使用，所以应当继续使用 `sp` 作为栈顶地址
/// 
/// ### 用户线程 [`TrapFrame`] 的存放
/// > 1. 线程初始化时，一个 `TrapFrame` 放置在内核栈顶，`sp` 指向 `TrapFrame` 的位置
/// >   （即栈顶 - `size_of::<TrapFrame>()`）
/// > 2. 切换到线程，执行 `__restore` 时，将 `TrapFrame` 的数据恢复到寄存器中后，
/// >   会将 `TrapFrame` 出栈（即 `sp += size_of::<TrapFrame>()`），
/// >   然后保存 `sp` 至 `sscratch`（此时 `sscratch` 即为内核栈顶）
/// > 3. 发生中断时，将 `sscratch` 和 `sp` 互换，入栈一个 `TrapFrame` 并保存数据
/// 
/// 容易发现，用户线程的 `TrapFrame` 一定保存在内核栈顶。因此，当线程需要运行时，
/// 从 [`Thread`] 中取出 `TrapFrame` 然后置于内核栈顶即可
/// 
/// ### 内核线程 [`TrapFrame`] 的存放
/// > 1. 线程初始化时，一个 `TrapFrame` 放置在内核栈顶，`sp` 指向 `TrapFrame` 的位置
/// >   （即栈顶 - `size_of::<TrapFrame>()`）
/// > 2. 切换到线程，执行 `__restore` 时，将 `TrapFrame` 的数据恢复到寄存器中后，
/// >   内核栈便不再被内核线程所使用
/// > 3. 发生中断时，直接在 `sp` 上入栈一个 `TrapFrame`
/// > 4. 从中断恢复时，内核线程已经从 `TrapFrame` 中恢复了 `sp`，相当于自动释放了 `TrapFrame`
/// >   和中断处理流程所涉及的栈空间
#[repr(align(16))]
#[repr(C)]
pub struct KernelStack([u8; STACK_SIZE]);

lazy_static! {
    /// 公用的内核栈
    pub static ref KERNEL_STACK: KernelStack = KernelStack([0; STACK_SIZE]);
}

impl KernelStack {
    /// 在栈顶加入 TrapFrame 并且返回 sp
    pub fn push_trap_frame(&self, trap_frame: TrapFrame) -> usize {
        let push_address = &self as *const _ as usize + STACK_SIZE - size_of::<TrapFrame>();
        unsafe {
            *(push_address as *mut TrapFrame) = trap_frame;
        }
        push_address
    }
}
