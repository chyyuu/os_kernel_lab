## 封装 SBI 接口

### 代码整理

将一切都写在一个 `main.rs` 中终究是一个不好的习惯，我们将代码分为不同模块整理一下。

我们先将 `console_putchar` 函数删掉，并将 `rust_main` 中调用 `console_putchar` 的部分也删除。

随后将 `rust_main` 抽取到`init.rs`中：

```rust
// src/init.rs

global_asm!(include_str!("boot/entry64.asm"));

#[no_mangle]
extern "C" fn rust_main() -> ! {
    loop {}
}
```

将语义项们抽取到`lang_items.rs`中：

```rust
// src/lang_items.rs

use core::panic::PanicInfo;

#[panic_handler]
fn panic(_: &PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
extern "C" fn abort() -> ! {
    panic!("abort!");
}
```

并在代表`os crate`的 `lib.rs` 中引用这两个子模块：

```rust
// src/lib.rs

#![no_std]
#![feature(asm)]
#![feature(global_asm)]

mod init;
mod lang_items;
```

以及只需使用 `os crate` 的孤零零的 `main.rs`。

```rust
// src/main.rs

#![no_std]
#![no_main]

#[allow(unused_imports)]
use os;
```

### 使用 OpenSBI 提供的服务

OpenSBI 实际上不仅起到了 bootloader 的作用，还为我们提供了一些服务供我们在编写内核时使用。这层接口称为 SBI (Supervisor Binary Interface)，是 S-Mode 的 kernel 和 M-Mode 执行环境之间的标准接口。

我们查看 [OpenSBI 文档 # legacy sbi extension](https://github.com/riscv/riscv-sbi-doc/blob/master/riscv-sbi.adoc#legacy-sbi-extension-extension-ids-0x00-through-0x0f) ，里面包含了一些以 C 函数格式给出的我们可以调用的接口。

上一节中我们的 `console_putchar` 函数类似于调用下面的接口来实现的：

```c
void sbi_console_putchar(int ch)
```

实际的过程是这样的：我们通过 ecall 发起系统调用。OpenSBI 会检察发起的系统调用的编号，如果编号在 `0-8` 之间，则进行处理，否则交由我们自己的中断处理程序处理（暂未实现）。

> 实现了编号在 `0-8` 之间的系统调用，具体请看 [OpenSBI 文档 # function list](https://github.com/riscv/riscv-sbi-doc/blob/master/riscv-sbi.adoc#function-listing-1)

执行 ecall 前需要指定系统调用的编号，传递参数。一般而言，$$a_7$$ 为系统调用编号，$$a_0 , a_1 , a_2$$ 为参数：

```rust
// src/lib.rs

mod sbi;
```

```rust
// src/sbi.rs

//! Port from sbi.h
#![allow(dead_code)]

#[inline(always)]
fn sbi_call(which: usize, arg0: usize, arg1: usize, arg2: usize) -> usize {
    let ret;
    unsafe {
        asm!("ecall"
            : "={x10}" (ret)
            : "{x10}" (arg0), "{x11}" (arg1), "{x12}" (arg2), "{x17}" (which)
            : "memory"
            : "volatile");
    }
    ret
}
```

> **[info] 函数调用与 calling convention **
>
> 我们知道，编译器将高级语言源代码翻译成汇编代码。对于汇编语言而言，在最简单的编程模型中，所能够利用的只有指令集中提供的指令、各通用寄存器、 CPU 的状态、内存资源。那么，在高级语言中，我们进行一次函数调用，编译器要做哪些工作利用汇编语言来实现这一功能呢？
>
> 显然并不是仅用一条指令跳转到被调用函数开头地址就行了。我们还需要考虑：
>
> - 如何传递参数？
> - 如何传递返回值？
> - 如何保证函数返回后能从我们期望的位置继续执行？
>
> 等更多事项。通常编译器按照某种规范去翻译所有的函数调用，这种规范被称为 [calling convention](https://en.wikipedia.org/wiki/Calling_convention) 。值得一提的是，为了实现函数调用，我们需要预先分配一块内存作为 **调用栈** ，后面会看到调用栈在函数调用过程中极其重要。你也可以理解为什么第一章刚开始我们就要分配栈了。

对于参数比较少且是基本数据类型的时候，我们从左到右使用寄存器 $$a_0 \sim a_7$$ 就可以完成参数的传递。（可参考 [riscv calling convention](https://riscv.org/wp-content/uploads/2015/01/riscv-calling.pdf)）

然而，如这种情况一样，设置寄存器并执行汇编指令，这超出了 Rust 语言的描述能力。然而又与之前 `global_asm!` 大段插入汇编代码不同，我们要把 `u8` 类型的单个字符传给 $$a_0$$ 作为输入参数，这种情况较为强调 Rust 与汇编代码的交互。此时我们通常使用 **内联汇编（inline assembly）** 。

> **[info] 拓展内联汇编**
>
> Rust 中拓展内联汇编的格式如下：
>
> ```rust
> asm!(assembler template
> 	: /* output operands */
> 	: /* input operands */
> 	: /* clobbered registers list */
> 	: /* option */
> );
> ```
>
> 其中：
>
> - `assembler template` 给出字符串形式的汇编代码；
> - `output operands` 以及 `input operands` 分别表示输出和输入，体现着汇编代码与 Rust 代码的交互。每个输出和输入都是用 `"constraint"(expr)` 的形式给出的，其中 `expr` 部分是一个 Rust 表达式作为汇编代码的输入、输出，通常为了简单起见仅用一个变量。而 `constraint` 则是你用来告诉编译器如何进行参数传递；
> - `clobbered registers list` 需要给出你在整段汇编代码中，除了用来作为输入、输出的寄存器之外，还曾经显式/隐式的修改过哪些寄存器。由于编译器对于汇编指令所知有限，你必须手动告诉它“我可能会修改这个寄存器”，这样它在使用这个寄存器时就会更加小心；
> - `option` 是 Rust 语言内联汇编 **特有** 的(相对于 C 语言)，用来对内联汇编整体进行配置。
> - 如果想进一步了解上面例子中的内联汇编(**"asm!"**)，请参考[附录：内联汇编](../appendix/inline_asm.md)。

输出部分，我们将结果保存到变量 `ret` 中，限制条件 `{x10}` 告诉编译器使用寄存器 $$x_{10}(a_0)$$ ，前面的 `=` 表明汇编代码会修改该寄存器并作为最后的返回值。一般情况下 `output operands` 的 constraint 部分前面都要加上 `=` 。

输入部分，我们分别通过寄存器 $$x_{10}(a_0),x_{11}(a_1),x_{12}(a_2),x_{17}(a_7)$$ 传入参数 *arg0,arg1,arg2,which* ，它们分别代表接口可能所需的三个输入参数（*arg0,arg1,arg2*），以及用来区分我们调用的是哪个接口的 `SBI Extension ID(*which*)` 。这里之所以提供三个输入参数是为了将所有接口囊括进去，对于某些接口有的输入参数是冗余的，比如*sbi_console_putchar* 由于只需一个输入参数，它就只关心寄存器 $$a_0$$ 的值。

在 clobbered registers list 中，出现了一个 `"memory"` ，这用来告诉编译器汇编代码隐式的修改了在汇编代码中未曾出现的某些寄存器。所以，它也不能认为汇编代码中未出现的寄存器就会在内联汇编前后保持不变了。

在 option 部分出现了 `"volatile"` ，我们可能在很多地方看到过这个单词。不过在内联汇编中，主要意思是告诉编译器，不要将内联汇编代码移动到别的地方去。我们知道，编译器通常会对翻译完的汇编代码进行优化，其中就包括对指令的位置进行调换。像这种情况，调换可能就会产生我们预期之外的结果。谨慎起见，我们针对内联汇编禁用这一优化。

接着利用 `sbi_call` 参考 OpenSBI 文档实现对应的接口：

```rust
// src/sbi.rs

pub fn console_putchar(ch: usize) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}

pub fn console_getchar() -> usize {
    sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0)
}

...

const SBI_SET_TIMER: usize = 0;
const SBI_CONSOLE_PUTCHAR: usize = 1;
const SBI_CONSOLE_GETCHAR: usize = 2;
const SBI_CLEAR_IPI: usize = 3;
const SBI_SEND_IPI: usize = 4;
const SBI_REMOTE_FENCE_I: usize = 5;
const SBI_REMOTE_SFENCE_VMA: usize = 6;
const SBI_REMOTE_SFENCE_VMA_ASID: usize = 7;
const SBI_SHUTDOWN: usize = 8;
```

现在我们比较深入的理解了 `console_putchar` 到底是怎么一回事。下一节我们将使用 `console_putchar` 实现格式化输出，为后面的调试提供方便。