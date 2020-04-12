## 状态的保存与恢复

涉及到寄存器的操作，我们就必须再用汇编来编写 TrapFrame 保存与恢复的相应代码。

### 代码流程

在直接写汇编之前，让我们先用伪代码描述一下我们需要进行的工作

```pseudo
进入中断（__interrupt）:
    # 在栈上开辟一段空间
    sp -= sizeof(TrapFrame)
    # 为了存放 TrapFrame，sp 已经被修改，而我们实际上应该存原本的 sp
    save(sp + sizeof(TrapFrame))
    # 保存所有其他通用寄存器
    for reg in general_registers where reg is not sp:
        save(reg)
    # 保存相关的 CSR 寄存器
    save(sstatus)
    save(sepc)
    save(scause)
    save(stval)
    # 跳转至中断处理函数
    handle_interrupt()

离开中断（__restore）:
    # 恢复相关的 CSR 寄存器
    load(sstatus)
    load(sepc)
    # 恢复所有通用寄存器
    for reg in general_registers where reg is not sp:
        load(reg)
    # 最后恢复 sp
    load(sp)
    # 回到 sepc 发生中断的位置
    # 中断处理流程可能修改了 sepc（例如让 sepc 指向中断的后一条指令）
    sret
```

### 编写汇编

相应的代码包含在 `os/src/asm/interrupt.asm` 中。

### 思考

为什么保存时保存了四个 CSR 寄存器，而恢复时只恢复了 `sstatus` 和 `sepc` 这两个？

{% reveal %}
> 保存寄存器有两种情况
> - 一种是通用寄存器和 `sstatus`：保存到 `TrapFrame`，使用寄存器进行中断处理流程，从  `TrapFrame` 中恢复  
> 这样即便中间再发生中断，也不会影响处理流程
> - 一种是其他 CSR 寄存器：被硬件自动设置，保存到 `TrapFrame`，从 `TrapFrame` 中读取进 行中断处理  
> 这样即便中间再发生中断，原本中断的处理流程读取的是已保存的 `TrapFrame`，也不会受到影响
> 
> 而 `sepc` 则比较特殊，它实际上会被操作系统进行修改，从 `TrapFrame` 中恢复时后，会立即在 `sret` 中使用，替代当前的 `pc`，使得程序执行流回到中断前的程序中
{% endreveal %}