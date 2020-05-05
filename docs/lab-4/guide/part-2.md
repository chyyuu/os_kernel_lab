## 线程切换

### TrapFrame

在中断的章节，我们就用 `TrapFrame` 的概念来帮助一个流程被中断或异常打断处理完再恢复回去的过程，而在这里，我们将用这个概念完成线程的切换。回顾一下，`TrapFrame` 是长这样的：

{% label %}os/src/interrupt/trap_frame.rs{% endlabel %}
```rust
#[repr(C)]
#[derive(Clone, Copy)]
pub struct TrapFrame {
    /// 通用寄存器
    pub x: [usize; 32],
    /// 保存诸多状态位的特权态寄存器
    pub sstatus: Sstatus,
    /// 保存中断地址的特权态寄存器
    pub sepc: usize,
}
```

于是，为了完成线程的切换，我们需要做的就是把当前的执行状态存在上面的 `x` 和 `sstatus` 中，然后为了以后可以切换回去，就把返回之后继续要执行的地址放在 `sepc` 中，然后通过原来的中断恢复返回机制实现跳转和切换。

### 修改中断处理

在之前的 rCore 设计中采用了 idle 线程来管理线程的调度，但是仔细思考一下，调度或者说切换线程一定会发生在某个中断到来的时候，这意味着之前的设计多少还是有些冗余的成分。而在这里，我们将彻底取消 idle 线程的概念，在中断处理时，要恢复回去的时候，直接把要切换的线程切换掉。

于是，我们需要修改之前的设计，让 `handle_interrupt` 返回一个具体的 `TrapFrame`，让之前的 `__restore` 机制读取这个返回值直接返回到对应的线程上下文中。

{% label %}os/src/interrupt/handler.rs{% endlabel %}
```rust
/// 中断的处理入口
///
/// `interrupt.asm` 首先保存寄存器至 TrapFrame，其作为参数传入此函数
/// 具体的中断类型需要根据 TrapFram::scause 来推断，然后分别处理
#[no_mangle]
pub fn handle_interrupt(trap_frame: &mut TrapFrame, scause: Scause, stval: usize) -> *mut TrapFrame{
    match scause.cause() {
        // 断点中断（ebreak）
        Trap::Exception(Exception::Breakpoint) => breakpoint(trap_frame),
        // 时钟中断
        Trap::Interrupt(Interrupt::SupervisorTimer) => supervisor_timer(trap_frame),
        // 其他情况未实现
        _ => unimplemented!("{:?}: {:x?}, stval: 0x{:x}", scause.cause(), trap_frame, stval),
    }
}

/// 处理 ebreak 断点
///
/// 继续执行，其中 `sepc` 增加 2 字节，以跳过当前这条 `ebreak` 指令
fn breakpoint(trap_frame: &mut TrapFrame) -> *mut TrapFrame {
    println!("Breakpoint at 0x{:x}", trap_frame.sepc);
    trap_frame.sepc += 2;
    trap_frame
}

/// 处理时钟中断
fn supervisor_timer(trap_frame: &mut TrapFrame) -> *mut TrapFrame {
    timer::tick();
    PROCESSOR.get().tick(trap_frame)
}
```

可以看到，当发生断点中断时，直接返回原来的上下文（修改一下 `sepc`）；而如果是时钟中断的时候，我们返回了 `PROCESSOR.get().tick(trap_frame)` 作为上下文，到这里 `PROCESSOR` 你可以认为是一个调度器，这个 `tick` 函数返回了我们要切换到的线程的上下文 `TrapFrame`。更具体的 `PROCESSOR` 的设计可以在后面见到。

### interrupt.asm

还记得我们是调用 `handle_interrupt` 而且如何具体恢复的吗？是利用了 `os/src/asm/interrupt.asm`，现在多了线程的概念，我们上面的 `handle_interrupt` 也有了些变化，那么我们也需要对应的修改：

{% label %}os/asm/interrupt.asm{% endlabel %}
```asm
# 宏：将寄存器存到栈上
.macro SAVE reg, offset
    sd  \reg, \offset*8(sp)
.endm

# 宏：将寄存器从栈中取出
.macro LOAD reg, offset
    ld  \reg, \offset*8(sp)
.endm

    .section .text
    .globl __interrupt
# 进入中断
# 保存 TrapFrame 并且进入 rust 中的中断处理函数 interrupt::handler::handle_interrupt()
__interrupt:
    # 涉及到用户线程时，保存 TrapFrame 就必须使用内核栈
    # 否则如果用户线程的栈发生缺页异常，将无法保存 TrapFrame
    # 因此，我们使用 sscratch 寄存器：
    # 处于用户线程时，保存内核栈地址；处于内核线程时，保存 0
    
    # csrrw rd, csr, rs1：csr 的值写入 rd；同时 rs1 的值写入 csr
    csrrw   sp, sscratch, sp
    bnez    sp, _from_user
_from_kernel:
    csrr    sp, sscratch
_from_user:
    # 此时 sscratch：原先的 sp；sp：内核栈地址
    # 在内核栈开辟 TrapFrame 的空间
    addi    sp, sp, -36*8
    
    # 保存通用寄存器，除了 x0（固定为 0）
    SAVE    x1, 1
    # 将原来的 sp（即 x2）保存
    # 同时 sscratch 写 0，因为即将进入*内核线程*的中断处理流程
    csrrw   x1, sscratch, x0
    SAVE    x1, 2
    SAVE    x3, 3
    SAVE    x4, 4
    SAVE    x5, 5
    SAVE    x6, 6
    SAVE    x7, 7
    SAVE    x8, 8
    SAVE    x9, 9
    SAVE    x10, 10
    SAVE    x11, 11
    SAVE    x12, 12
    SAVE    x13, 13
    SAVE    x14, 14
    SAVE    x15, 15
    SAVE    x16, 16
    SAVE    x17, 17
    SAVE    x18, 18
    SAVE    x19, 19
    SAVE    x20, 20
    SAVE    x21, 21
    SAVE    x22, 22
    SAVE    x23, 23
    SAVE    x24, 24
    SAVE    x25, 25
    SAVE    x26, 26
    SAVE    x27, 27
    SAVE    x28, 28
    SAVE    x29, 29
    SAVE    x30, 30
    SAVE    x31, 31

    # 取出 CSR 并保存
    csrr    t0, sstatus
    csrr    t1, sepc
    SAVE    t0, 32
    SAVE    t1, 33
    # 调用 handle_interrupt，传入参数
    # trap_frame: &mut TrapFrame
    mv      a0, sp
    # scause: Scause
    csrr    a1, scause
    # stval: usize
    csrr    a2, stval
    jal handle_interrupt

    .globl __restore
# 离开中断
# 从 TrapFrame 中恢复所有寄存器，并跳转至 TrapFrame 中 sepc 的位置
__restore:
    # 从 a0 中读取 sp
    mv      sp, a0
    # 恢复 CSR
    LOAD    t0, 32
    LOAD    t1, 33
    # 思考：如果恢复的是用户线程，此时的 sstatus 是用户态还是内核态
    csrw    sstatus, t0
    csrw    sepc, t1
    # 根据即将恢复的线程属于用户还是内核，恢复 sscratch
    # 检查 sstatus 上的 SPP 标记
    andi    t0, t0, 1 << 8
    bnez    t0, _to_kernel
_to_user:
    # 将要进入用户态，需要将内核栈地址写入 sscratch
    addi    t0, sp, 36*8
    csrw    sscratch, t0
_to_kernel:
    # 如果要进入内核态，sscratch 保持为 0 不变

    # 恢复通用寄存器
    LOAD    x1, 1
    LOAD    x3, 3
    LOAD    x4, 4
    LOAD    x5, 5
    LOAD    x6, 6
    LOAD    x7, 7
    LOAD    x8, 8
    LOAD    x9, 9
    LOAD    x10, 10
    LOAD    x11, 11
    LOAD    x12, 12
    LOAD    x13, 13
    LOAD    x14, 14
    LOAD    x15, 15
    LOAD    x16, 16
    LOAD    x17, 17
    LOAD    x18, 18
    LOAD    x19, 19
    LOAD    x20, 20
    LOAD    x21, 21
    LOAD    x22, 22
    LOAD    x23, 23
    LOAD    x24, 24
    LOAD    x25, 25
    LOAD    x26, 26
    LOAD    x27, 27
    LOAD    x28, 28
    LOAD    x29, 29
    LOAD    x30, 30
    LOAD    x31, 31

    # 恢复 sp（又名 x2）这里最后恢复是为了上面可以正常使用 LOAD 宏
    LOAD    x2, 2
    sret
```

可以看到，进入 `__interrupt` 之后，我们先根据 `sscratch` 的值判断是从内核线程还是用户线程来的，如果是 0 就是内核线程否则是用户线程（存的是共用的内核栈）。如果是从内核来的，我们就不用共用的内核栈了，直接还是用它自己的内核栈。后面不论是内核还是用户，都会把当前的寄存器信息压在对应的栈上，压成一个 `TrapFrame`、`scause` 和 `stval`，最后再跳转到 `handle_interrupt` 的 Rust 逻辑中。同时，我们会把 `sscratch` 寄存器改成 0，表示异常的处理过程是内核态。

思考，为什么我们不把内核线程也共用内核栈呢？

{% reveal %}
> 如果在中断处理的时候（这个时候是内核态），又发生了异常（比如缺页），这个时候如果还用那个共用的栈，就会崩溃。我们需要保证的是共用的栈在需要用的时候一定是空的（中断的逻辑返回之后就没用了）。但是，如果为了支持嵌套异常，我们内核栈需要不断叠加，不断把嵌套产生的 `TrapFrame` 往上压，而不是压在最开始的时候。
{% endreveal %}

思考，如果运行这部分逻辑的时候来一个时钟中断怎么办？

{% reveal %}
> 根本不会产生时钟中断，因为 RISC-V 不支持硬件基本的中断嵌套，在进中断后会屏蔽掉全部的中断。但是是可以嵌套异常的（上一个问题），比如在中断处理的时候缺页了。
{% endreveal %}

最后是恢复的逻辑，`handle_interrupt` 返回了一个 `TrapFrame` 的地址，我们直接把这个地址上的 `TrapFrame` 读出来，根据是否是用户线程设置好 `sscratch` 最后返回到 `sepc` 上就完成了切换同时也是一种中断恢复的实现。

思考，如果是用户线程从中断中恢复，我们直接把 `sscratch` 改成了返回的 `TrapFrame` 的高地址，这样做会不会在更高的地址上留下一些其他违背清空的空间造成对共用栈的浪费？

{% reveal %}
> 不会，因为我们返回的 `TrapFrame` 和调用 `handle_interrupt` 时传进去的是一个，只是内容被改了。而传进去的时候，栈放的第一个东西就是 `TrapFrame`，这个结构的下面（栈元素的下面意味着更高的地址）就没有其他东西，所以不管是用户线程还是内核线程恢复，中断逻辑在栈上产生的东西会被彻底清掉。
{% endreveal %}

至此，我们完成了线程的切换，而如何启动一个新的线程还是一个问题，后面我们进一步封装 `Thread` 这个类，通过精妙地构造 `TrapFrame` 中的内容等等来实现一个新线程的启动等操作。