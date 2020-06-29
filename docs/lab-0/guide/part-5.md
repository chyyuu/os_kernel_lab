## 生成内核镜像

### 安装 binutils 工具集

为了查看和分析生成的可执行文件，我们首先需要安装一套名为 binutils 的命令行工具集，其中包含了 objdump 和 objcopy 等常用工具。

Rust 社区提供了一个 cargo-binutils 项目，可以帮助我们方便地调用 Rust 内置的 LLVM binutils。我们用以下命令安装它：

{% label %}运行命令{% endlabel %}
```bash
cargo install cargo-binutils
rustup component add llvm-tools-preview
```

之后尝试使用 `rust-objdump --version` 命令看看是否安装成功。

> **[info] `rust-objdump` 找不到？**
>
> `cargo install` 会默认将二进制文件添加到 `${HOME}/.cargo/bin` 中，我们将这个路径加入到 `$PATH` 环境变量中之后就能找到需要的 `rust-objdump` 命令了。

> **[info] 其它选择：GNU 工具链**
>
> 除了内置的 LLVM 工具链以外，我们也可以使用 GNU 工具链，其中还包含了 GCC 等 C 语言工具链。
>
> 我们可以在 https://www.sifive.com/boards#software 上去下载最新的适合自己操作系统的预编译版本。

### 查看生成的可执行文件

我们编译之后的产物为 `os/target/riscv64imac-unknown-none-elf/debug/os`，让我们先看看它的文件类型：

{% label %}运行输出{% endlabel %}
```bash
$ file target/riscv64imac-unknown-none-elf/debug/os
target/riscv64imac-unknown-none-elf/debug/os: ELF 64-bit LSB executable, UCB RISC-V, version 1 (SYSV), statically linked, with debug_info, not stripped
```

从中，我们可以看出它是一个 64 位的 elf 格式的可执行文件，架构是 RISC-V；链接方式为静态链接；not stripped 指的是里面符号表的信息未被剔除，而这些信息在调试程序时会用到，程序正常执行时通常不会使用。

接下来使用刚刚安装的工具链中的 rust-objdump 工具看看它的具体信息：

{% label %}运行输出{% endlabel %}
```clike
$ rust-objdump target/riscv64imac-unknown-none-elf/debug/os -x --arch-name=riscv64

target/riscv64imac-unknown-none-elf/debug/os:	file format ELF64-riscv

architecture: riscv64
start address: 0x0000000000011000

Sections:
Idx Name          Size     VMA          Type
  0               00000000 0000000000000000
  1 .text         0000000c 0000000000011000 TEXT
  2 .debug_str    000004f6 0000000000000000
  3 .debug_abbrev 0000010e 0000000000000000
  4 .debug_info   00000633 0000000000000000
  5 .debug_aranges 00000040 0000000000000000
  6 .debug_ranges 00000030 0000000000000000
  7 .debug_macinfo 00000001 0000000000000000
  8 .debug_pubnames 000000ce 0000000000000000
  9 .debug_pubtypes 000003a2 0000000000000000
 10 .debug_frame  00000068 0000000000000000
 11 .debug_line   00000059 0000000000000000
 12 .comment      00000012 0000000000000000
 13 .symtab       00000108 0000000000000000
 14 .shstrtab     000000b4 0000000000000000
 15 .strtab       0000002d 0000000000000000

SYMBOL TABLE:
0000000000000000 l    df *ABS*	00000000 3k1zkxjipadm3tm5
0000000000000000         .debug_frame	00000000
0000000000011000         .text	00000000
0000000000011000         .text	00000000
0000000000011000         .text	00000000
000000000001100c         .text	00000000
0000000000000000         .debug_ranges	00000000
0000000000000000         .debug_info	00000000
0000000000000000         .debug_line	00000000 .Lline_table_start0
0000000000011000 g     F .text	0000000c _start
Program Header:
    PHDR off    0x0000000000000040 vaddr 0x0000000000010040 paddr 0x0000000000010040 align 2**3
         filesz 0x00000000000000e0 memsz 0x00000000000000e0 flags r--
    LOAD off    0x0000000000000000 vaddr 0x0000000000010000 paddr 0x0000000000010000 align 2**12
         filesz 0x0000000000000120 memsz 0x0000000000000120 flags r--
    LOAD off    0x0000000000001000 vaddr 0x0000000000011000 paddr 0x0000000000011000 align 2**12
         filesz 0x0000000000001000 memsz 0x0000000000001000 flags r-x
   STACK off    0x0000000000000000 vaddr 0x0000000000000000 paddr 0x0000000000000000 align 2**64
         filesz 0x0000000000000000 memsz 0x0000000000000000 flags rw-

Dynamic Section:

```

我们按顺序逐个查看：

- start address：程序的入口地址
- Sections：从这里我们可以看到程序各段的各种信息。后面以 debug 开头的段是调试信息
- SYMBOL TABLE：符号表，从中我们可以看到程序中所有符号的地址。例如 `_start` 函数就位于入口地址上
- Program Header：程序加载时所需的段信息
  - 其中的 off 是它在文件中的位置，vaddr 和 paddr 是要加载到的虚拟地址和物理地址，align 规定了地址的对齐，filesz 和 memsz 分别表示它在文件和内存中的大小，flags 描述了相关权限（r 表示可读，w 表示可写，x 表示可执行）

在这里我们使用的是 `-x` 来查看程序的元信息，下面我们用 `-d` 来对代码进行反汇编：

{% label %}运行输出{% endlabel %}
```bash
$ rust-objdump target/riscv64imac-unknown-none-elf/debug/os -d --arch-name=riscv64

target/riscv64imac-unknown-none-elf/debug/os:	file format ELF64-riscv

Disassembly of section .text:

0000000000011000 _start:
   11000: 41 11                        	addi	sp, sp, -16
   11002: 06 e4                        	sd	ra, 8(sp)
   11004: 22 e0                        	sd	s0, 0(sp)
   11006: 00 08                        	addi	s0, sp, 16
   11008: 09 a0                        	j	2
   1100a: 01 a0                        	j	0
```

可以看到其中只有一个 `_start` 函数，里面什么都不做，就一个死循环。

### 生成镜像

我们之前生成的 elf 格式可执行文件有以下特点：

- 含有冗余的调试信息，使得程序体积较大
- 需要对 Program Header 部分进行手动解析才能知道各段的信息，而这需要我们了解 Program Header 的二进制格式，并以字节为单位进行解析

由于我们目前没有调试的手段，不需要调试信息；同时也不会解析 elf 格式文件，所以我们可以使用工具 rust-objcopy 从 elf 格式可执行文件生成内核镜像：

{% label %}运行命令{% endlabel %}
```bash
rust-objcopy target/riscv64imac-unknown-none-elf/debug/os --strip-all -O binary target/riscv64imac-unknown-none-elf/debug/kernel.bin
```

这里 `--strip-all` 表明丢弃所有符号表及调试信息，`-O binary` 表示输出为二进制文件。

至此，我们编译并生成了内核镜像 `kernel.bin` 文件。接下来，我们将使用 QEMU 模拟器真正将我们的内核镜像跑起来。不过在此之前还需要完成两个工作：**调整内存布局**和**重写入口函数**。
