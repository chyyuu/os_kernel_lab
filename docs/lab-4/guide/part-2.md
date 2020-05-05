## 线程切换

### Context

在中断的章节，我们就用 `Context` 的概念来帮助一个流程被中断或异常打断处理完再恢复回去的过程，而在这里，我们将用这个概念完成线程的切换。回顾一下，`Context` 是长这样的：

{% label %}os/src/interrupt/context.rs{% endlabel %}
```rust
#[repr(C)]
#[derive(Clone, Copy)]
pub struct Context {
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

于是，我们需要修改之前的设计，让 `handle_interrupt` 返回一个具体的 `Context`，让之前的 `__restore` 机制读取这个返回值直接返回到对应的线程上下文中。

{% label %}os/src/interrupt/handler.rs{% endlabel %}
```rust
/// 中断的处理入口
///
/// `interrupt.asm` 首先保存寄存器至 Context，其作为参数传入此函数
/// 具体的中断类型需要根据 Context::scause 来推断，然后分别处理
#[no_mangle]
pub fn handle_interrupt(context: &mut Context, scause: Scause, stval: usize) -> *mut Context{
    match scause.cause() {
        // 断点中断（ebreak）
        Trap::Exception(Exception::Breakpoint) => breakpoint(context),
        // 时钟中断
        Trap::Interrupt(Interrupt::SupervisorTimer) => supervisor_timer(context),
        // 其他情况未实现
        _ => unimplemented!("{:?}: {:x?}, stval: 0x{:x}", scause.cause(), context, stval),
    }
}

/// 处理 ebreak 断点
///
/// 继续执行，其中 `sepc` 增加 2 字节，以跳过当前这条 `ebreak` 指令
fn breakpoint(context: &mut Context) -> *mut Context {
    println!("Breakpoint at 0x{:x}", context.sepc);
    context.sepc += 2;
    context
}

/// 处理时钟中断
fn supervisor_timer(context: &mut Context) -> *mut Context {
    timer::tick();
    PROCESSOR.get().tick(context)
}
```

可以看到，当发生断点中断时，直接返回原来的上下文（修改一下 `sepc`）；而如果是时钟中断的时候，我们返回了 `PROCESSOR.get().tick(context)` 作为上下文，到这里 `PROCESSOR` 你可以认为是一个调度器，这个 `tick` 函数返回了我们要切换到的线程的上下文 `Context`。更具体的 `PROCESSOR` 的设计可以在后面见到。

### interrupt.asm

还记得我们是调用 `handle_interrupt` 而且如何具体恢复的吗？是利用了 `os/src/asm/interrupt.asm`，现在多了线程的概念，我们上面的 `handle_interrupt` 也有了些变化，那么我们也需要对应的修改：

{% label %}os/src/asm/interrupt.asm{% endlabel %}
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
# 保存 Context 并且进入 rust 中的中断处理函数 interrupt::handler::handle_interrupt()
__interrupt:
    # 涉及到用户线程时，保存 Context 就必须使用内核栈
    # 否则如果用户线程的栈发生缺页异常，将无法保存 Context
    # 因此，我们使用 sscratch 寄存器：
    # 处于用户线程时，保存内核栈地址；处于内核线程时，保存 0
    
    # csrrw rd, csr, rs1：csr 的值写入 rd；同时 rs1 的值写入 csr
    csrrw   sp, sscratch, sp
    bnez    sp, _from_user
_from_kernel:
    csrr    sp, sscratch
_from_user:
    # 此时 sscratch：原先的 sp；sp：内核栈地址
    # 在内核栈开辟 Context 的空间
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
    # context: &mut Context
    mv      a0, sp
    # scause: Scause
    csrr    a1, scause
    # stval: usize
    csrr    a2, stval
    jal handle_interrupt

    .globl __restore
# 离开中断
# 从 Context 中恢复所有寄存器，并跳转至 Context 中 sepc 的位置
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

可以看到，进入 `__interrupt` 之后，我们先根据 `sscratch` 的值判断是从内核线程还是用户线程来的，如果是 0 就是内核线程否则是用户线程（存的是共用的内核栈）。如果是从内核来的，我们就不用共用的内核栈了，直接还是用它自己的内核栈。后面不论是内核还是用户，都会把当前的寄存器信息压在对应的栈上，压成一个 `Context`、`scause` 和 `stval`，最后再跳转到 `handle_interrupt` 的 Rust 逻辑中。同时，我们会把 `sscratch` 寄存器改成 0，表示异常的处理过程是内核态。

思考，为什么我们不把内核线程也共用内核栈呢？

{% reveal %}
> 如果在中断处理的时候（这个时候是内核态），又发生了异常（比如缺页），这个时候如果还用那个共用的栈，就会崩溃。我们需要保证的是共用的栈在需要用的时候一定是空的（中断的逻辑返回之后就没用了）。但是，如果为了支持嵌套异常，我们内核栈需要不断叠加，不断把嵌套产生的 `Context` 往上压，而不是压在最开始的时候。
>
{% endreveal %}

思考，如果运行这部分逻辑的时候来一个时钟中断怎么办？

{% reveal %}
> 根本不会产生时钟中断，因为 RISC-V 不支持硬件基本的中断嵌套，在进中断后会屏蔽掉全部的中断。但是是可以嵌套异常的（上一个问题），比如在中断处理的时候缺页了。
>
{% endreveal %}

最后是恢复的逻辑，`handle_interrupt` 返回了一个 `Context` 的地址，我们直接把这个地址上的 `Context` 读出来，根据是否是用户线程设置好 `sscratch` 最后返回到 `sepc` 上就完成了切换同时也是一种中断恢复的实现。

思考，如果是用户线程从中断中恢复，我们直接把 `sscratch` 改成了返回的 `Context` 的高地址，这样做会不会在更高的地址上留下一些其他违背清空的空间造成对共用栈的浪费？

{% reveal %}
> 不会，因为我们返回的 `Context` 和调用 `handle_interrupt` 时传进去的是一个，只是内容被改了。而传进去的时候，栈放的第一个东西就是 `Context`，这个结构的下面（栈元素的下面意味着更高的地址）就没有其他东西，所以不管是用户线程还是内核线程恢复，中断逻辑在栈上产生的东西会被彻底清掉。
>
{% endreveal %}

至此，我们完成了线程的切换，而如何启动一个新的线程还是一个问题，后面我们进一步封装 `Thread` 这个类，通过精妙地构造 `Context` 中的内容等等来实现一个新线程的启动等操作。

### Thread 类

之前已经提到过了，一个 `Thread` 会包含下面几个信息：

{% label %}os/src/process/thread.rs{% endlabel %}
```rust
/// 线程的信息
pub struct Thread {
    /// 线程的栈
    pub stack: Stack,
    /// 线程执行上下文
    ///
    /// 当且仅当线程被暂停执行时，`context` 为 `Some`
    pub context: Mutex<Option<Context>>,
    /// 所属的进程
    pub process: Arc<RwLock<Process>>,
}
```

而现在，我们三样东西轮廓都有了，我们开始为 `Thread` 添加一些具体的方法，方便外面调用。首先是创建一个新的线程：

{% label %}os/src/process/thread.rs: impl Thread{% endlabel %}
```rust
/// 创建一个线程
pub fn new(
    process: Arc<RwLock<Process>>,
    entry_point: usize,
    arguments: Option<&[usize]>,
) -> MemoryResult<Arc<Thread>> {
    // 从地址空间中找一段空间存放栈
    let mut stack_range = Range::<VirtualAddress>::from(0..STACK_SIZE);
    while process.read().memory_set.overlap_with(stack_range.into()) {
        stack_range.start += STACK_SIZE;
        stack_range.end += STACK_SIZE;
    }
    // 构建栈，从进程中继承特权信息
    let stack = Stack::new(stack_range, process.read().is_user);
    // 映射这段空间
    process
        .write()
        .memory_set
        .add_segment(stack.get_segment())?;

    // 构建线程的 Context
    let context = Context {
        x: {
            let mut x = [0usize; 32];
            // 栈顶为新创建的栈顶
            x[2] = stack.top().into();
            // 写入参数，这里没有考虑一些特殊情况，比如参数大于 8 个或 struct 铺开等
            if let Some(args) = arguments {
                x[10..(10 + args.len())].copy_from_slice(args);
            }
            x
        },
        // sstatus 设置为，在 sret 之后，开启中断
        sstatus: {
            let mut sstatus = sstatus::read();
            if process.read().is_user {
                sstatus.set_spp(User);
            } else {
                sstatus.set_spp(Supervisor);
            }
            // 这样设置 SPIE 和 SIE 位，使得替换 sstatus 后关闭中断，
            // 而在 sret 到用户线程时开启中断。详见 SPIE 和 SIE 的定义
            sstatus.set_spie(true);
            sstatus.set_sie(false);
            sstatus
        },
        // sret 后进入 entry_point
        sepc: entry_point,
    };

    // 打包成线程
    let thread = Arc::new(Thread {
        stack,
        context: Mutex::new(Some(context)),
        process: process.clone(),
    });
    process.write().push_thread(thread.clone());
    Ok(thread)
}
```

这里的创建包括属于哪个进程，还有线程的开始执行点（一个函数的地址），已经执行函数的参数。第一个进行的是，我们首先找到一段进程没用的空间来作为新线程的栈空间，然后构造切换到线程的 `Context`，包括入口的参数（这里没有考虑复杂的情况，现在只是支持小等于 8 个 4 字节参数），还有 `sstatus` 寄存器，其中包括 `spp`（`sret` 后的模式）、`spie` 和 `sie` 寄存器。其中后两者的意思是在发生中断时 `sie` 会被置零（屏蔽中断），而 `spie` 会被赋值为 `sie` 的值，在 `sret` 的时候 `sie` 的值再恢复为 `spie` 的值，我们把 `spie` 预设为 1 也就意味着返回之后可以接受中断，同时 `sie` 为 0 意味着在那段恢复的逻辑（`__restore` 等）中操作 `sstatus` 寄存器不会发生中断以免发生意料之外的错误。更加具体的细节请参见 RISC-V 特权级手册。

下面还有两个比较简单的函数，这里一并给出：

{% label %}os/src/process/thread.rs: impl Thread{% endlabel %}
```rust
/// 执行一个线程
///
/// 激活对应进程的页表，并返回其 Context
pub fn run(&self) -> *mut Context {
    // 激活页表
    self.process.read().memory_set.activate();
    // 取出 Context
    let parked_frame = self.context.lock().take().unwrap();
    
    if self.process.read().is_user {
        // 用户线程则将 Context 放至内核栈顶
        KERNEL_STACK.push_context(parked_frame) as *mut Context
    } else {
        // 内核线程则将 Context 放至 sp 下
        let address = parked_frame.sp() - size_of::<Context>();
        let context = address.deref();
        *context = parked_frame;
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
```

上面的运行是说激活页表并返回一个 `Context` 出来，放在对应的栈上（`__restore` 会读取）；而下面的 `park` 函数是把一个在栈上的 `Context` 暂时存到当前的结构体中。

思考，在 `run` 函数中，我们第一句就激活了页表，后面的逻辑会不会乱套？

{% reveal %}
> 不会，因为全部进程包括用户进程都会有内核这段线性映射，不然连中断都没法处理了（不知道跳到哪里）。
>
{% endreveal %}

至此，我们终于完成了大部分进程和线程的逻辑，后面我们利用这些逻辑来实现真正的调度。