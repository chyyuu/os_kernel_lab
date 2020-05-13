## 内核栈

### 为什么 / 怎么做

在实现内核栈之前，让我们先检查一下需求，和我们的解决办法。

- **用户线程必须要有内核栈，而内核线程不需要**（内核线程要是挂了，我们可以打出『<span style="color: white; background-color: #00a2ed">您的 rCore 遇到问题，需要重新启动</span>』）
- **不是每个用户线程都需要一个独立的内核栈**，因为内核栈只会在中断时使用，而中断结束后就不再使用。不会有两个线程同时出现中断，**所以我们只需要实现一个共用的内核栈就可以了**。
- **每个用户线程都需要能够在中断时第一时间找到内核栈的地址**。这时，所有通用寄存器的值都无法预知。为此，**我们将内核栈的地址存放到内核态使用的特权寄存器 `sscratch` 中**。这个寄存器只能在内核态访问，这样在中断发生时，就可以安全地找到内核栈了。
- **需要支持中断嵌套**。实际上这个**不需要做什么**就已经可以做到了，因为在发生中断后，系统就进入了内核态，然后我们会切换到内核栈进行处理。此时如果再嵌套发生中断，由于已经处于内核态（算作内核线程），就会继续使用当前的栈（内核栈）进行下一个中断的处理。  

总结起来，我们的做法就是：

- 预留一段空间作为内核栈
- 运行用户线程时，在 `sscratch` 寄存器中保存内核栈指针  
  运行内核线程时，在 `sscratch` 中保存 0 以区分
- 如果用户线程遇到中断，则将 `Context` 压入 `sscratch` 指向的栈中（`Context` 的地址为 `sscratch - size_of::<Context>()`），同时修改 `sp` 为新的内核栈指针（此时 `sp` 也会被复制到 `a0` 作为 `handle_interrupt` 的参数）  
  如果内核线程遇到中断，则将 `Context` 压入当前的栈上
- 从中断中返回时（`__restore` 时），如果是用户线程，`a0` 应指向被压在内核栈中的 `Context`。此时应该出栈 `Context` 并且将栈顶保存到 `sscratch` 中  
  如果是内核线程，`a0` 应指向当前线程的栈中的 `Context`。此时直接将 `Context` 出栈即可

### 实现

#### 为内核栈预留空间

我们直接使用一个 `static` 来指定一段空间作为栈。

{% label %}os/src/process/kernel_stack.rs{% endlabel %}
```rust
/// 内核栈
#[repr(align(16))]
#[repr(C)]
pub struct KernelStack([u8; KERNEL_STACK_SIZE]);

/// 公用的内核栈
pub static KERNEL_STACK: KernelStack = KernelStack([0; STACK_SIZE]);
```

在我们创建线程时，需要使用的操作就是在内核栈顶压入一个初始状态 `Context`：

{% label %}os/src/process/kernel_stack.rs{% endlabel %}
```rust
impl KernelStack {
    /// 在栈顶加入 Context 并且返回新的栈顶指针
    pub fn push_context(&self, context: Context) -> *mut Context {
        // 栈顶
        let stack_top = &self as *const _ as usize + size_of::<Self>();
        // Context 的位置
        let push_address = (stack_top - size_of::<Context>()) as *mut Context;
        unsafe {
            *push_address = context;
        }
        push_address
    }
}
```

#### 修改 `interrupt.asm`

在这个汇编代码中，我们需要加入对 `sscratch` 的判断和使用。

{% label %}os/src/asm/interrupt.asm{% endlabel %}
```asm
__interrupt:
    # 涉及到用户线程时，保存 Context 就必须使用内核栈
    # 否则如果用户线程的栈发生缺页异常，将无法保存 Context
    # 因此，我们使用 sscratch 寄存器：
    # 处于用户线程时，保存内核栈地址；处于内核线程时，保存 0

    # 交换 sp 和 sscratch
    csrrw   sp, sscratch, sp
    bnez    sp, _from_user
_from_kernel:
    csrr    sp, sscratch
_from_user:
    # 此时 sscratch 为原先的 sp，sp 为内核栈地址
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

    # ...
```

以及事后的恢复：

{% label %}os/src/asm/interrupt.asm{% endlabel %}
```asm
__restore:
    # 从 a0 中读取 sp
    mv      sp, a0
    # 恢复 CSR
    LOAD    t0, 32
    LOAD    t1, 33
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
    # ...
```

### 小结

为了能够鲁棒地处理用户线程产生的异常，我们为用户线程准备好一个内核栈，发生中断时会切换到这里继续处理。

#### 思考

在栈的切换过程中，会不会导致一些栈空间没有被释放，或者被错误释放的情况？

在 `interrupt.asm` 中，有两处涉及将 `sp` 加减 `size_of::<Context>()` 的操作。但是无论用户还是内核线程都会执行压栈那一步，但只有用户线程会执行出栈那一步。这是为什么？
