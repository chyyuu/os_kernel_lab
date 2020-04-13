## RISC-V 与中断相关的寄存器和指令

> **[info] 回顾：RISC-V 中的机器态（Machine mode，机器模式，M 模式）**
> - 是 RISC-V 中的最高权限模式，一些底层操作的指令只能由机器态进行使用。
> - 是所有标准 RISC-V 处理器都必须实现的模式。
> - 默认所有中断实际上是交给机器态处理的，但是为了实现更多功能，机器态会将某些中断交由内核态处理。这些异常也正是我们编写操作系统所需要实现的。
> 
> **回顾：RISC-V 中的内核态（Supervisor mode，内核模式，S 模式）**
> - 通常为操作系统使用，可以访问一些 supervisor 级别的寄存器，通过这些寄存器对中断和虚拟内存映射进行管理。
> - Unix 系统中，大部分的中断都是内核态的系统调用。机器态可以通过异常委托机制（machine interrupt delegation）将一部分中断设置为不经过机器态，直接由内核态处理

在实验中，我们主要关心的就是内核态可以使用的一些特权指令和寄存器。其中关于中断的会在本章用到，而关于内存映射的部分将会在第三部分用到。

### 与中断相关的寄存器

在内核态和机器态中，RISC-V 设计了一些 CSR（Control and Status Registers）寄存器用来保存控制信息。目前我们关心的是其中涉及到控制中断的寄存器。

#### 发生中断时，硬件自动填写的寄存器

- `sepc`  
即 Exception Program Counter，用来记录触发中断的指令的地址。

  > 和我们之前学的 MIPS 32 系统不同，RISC-V 中不需要考虑延迟槽的问题。但是 RISC-V 中的指令不定长，如果中断处理需要恢复到异常指令后一条指令进行执行，就需要正确判断将 `pc` 寄存器加上多少字节。

- `scause`  
记录中断是否是硬件中断，以及具体的中断原因。

- `stval`  
`scause` 不足以存下中断所有的必须信息。例如缺页异常，就会将 `stval` 设置成需要访问但是不在内存中的地址，以便于操作系统将这个地址所在的页面加载进来。

#### 指导硬件处理中断的寄存器

- `stvec`  
设置内核态中断处理流程的入口地址。存储了一个基址 BASE 和模式 MODE：

  - MODE 为 0 表示 Direct 模式，即遇到中断便跳转至 BASE 进行执行。
  
  - MODE 为 1 表示 Vectored 模式，此时 BASE 应当指向一个向量，存有不同处理流程的地址，遇到中断会跳转至 `BASE + 4 * cause` 进行处理流程。

- `sstatus`  
具有许多状态位，控制全局中断使能等。

- `sie`  
即 Supervisor Interrupt-Enable，用来控制具体类型中断的使能，例如其中的 STIE 控制时钟中断使能。

- `sip`  
即 Supervisor Interrupt-Pending，和 `sie` 相对应，记录每种中断是否被触发。仅当 `sie` 和 `sip` 的对应位都为 1 时，意味着开中断且已发生中断，这时中断最终触发。

#### `sscratch`

（这个寄存器的用处会在实现线程时起到作用，目前仅了解即可）

在用户态，`sscratch` 保存内核栈的地址；在内核态，`sscratch` 的值为 0。

为了能够执行内核态的中断处理流程，仅有一个入口地址是不够的。中断处理流程很可能需要使用栈，而程序当前的用户栈是不安全的。因此，我们还需要一个预设的安全的栈空间，存放在这里。

在内核态中，`sp` 可以认为是一个安全的栈空间，`sscratch` 便不需要保存任何值。此时将其设为 0，可以在遇到中断时通过 `sscratch` 中的值判断中断前程序是否处于内核态。

### 与中断相关的指令

#### 进入和退出中断

- `ecall`  
触发中断，进入更高一层的中断处理流程之中。用户态进行系统调用进入内核态中断处理流程，内核态进行 SBI 调用进入机器态中断处理流程，使用的都是这条指令。

- `sret`  
从内核态返回用户态，同时将 `pc` 的值设置为 `sepc`。（如果需要返回到 `sepc` 后一条指令，就需要在 `sret` 之前修改 `sepc` 的值）

- `ebreak`  
触发一个断点。

- `mret`  
从机器态返回内核态，同时将 `pc` 的值设置为 `mepc`。

#### 操作 CSR

只有一系列特殊的指令（CSR Instruction）可以读写 CSR。尽管所有模式都可以使用这些指令，用户态只能只读的访问某几个寄存器。

为了让操作 CSR 的指令不被干扰，许多 CSR 指令都是结合了读写的原子操作。不过在实验中，我们只用到几个简单的指令。

- `csrrw dst, csr, src`（CSR Read Write）  
同时读写的原子操作，将指定 CSR 的值写入 `dst`，同时将 `src` 的值写入 CSR。

- `csrr dst, csr`（CSR Read）  
仅读取一个 CSR 寄存器。

- `csrw csr, src`（CSR Write）  
仅写入一个 CSR 寄存器。

- `csrc(i) csr, rs1`（CSR Clear）  
将 CSR 寄存器中指定的位清零，`csrc` 使用通用寄存器作为 mask，`csrci` 则使用立即数。

- `csrs(i) csr, rs1`（CSR Set）  
将 CSR 寄存器中指定的位置 1，`csrc` 使用通用寄存器作为 mask，`csrci` 则使用立即数。

### 了解更多

RISC-V 官方文档：

- CSR 寄存器（Chapter 4，p59）  
https://content.riscv.org/wp-content/uploads/2017/05/riscv-privileged-v1.10.pdf

- CSR 指令（Section 2.8，p33）  
https://content.riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf
