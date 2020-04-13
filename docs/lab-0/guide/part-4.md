## 编译为裸机目标

在默认情况下，Rust 尝试适配当前的系统环境，编译可执行程序。举个例子，如果你使用 x86_64 平台的 Windows 系统，Rust 将尝试编译一个扩展名为 `.exe` 的 Windows 可执行程序，并使用 `x86_64` 指令集。这个环境又被称作为你的宿主系统（Host System）。

为了描述不同的环境，Rust 使用一个称为目标三元组（Target Triple）的字符串  `<arch><sub>-<vendor>-<sys>-<abi>`。要查看当前系统的目标三元组，我们可以运行 `rustc --version --verbose`：

{% label %}运行输出{% endlabel %}
```bash
rustc 1.35.0-nightly (474e7a648 2019-04-07)
binary: rustc
commit-hash: 474e7a6486758ea6fc761893b1a49cd9076fb0ab
commit-date: 2019-04-07
host: x86_64-unknown-linux-gnu
release: 1.35.0-nightly
LLVM version: 8.0
```

上面这段输出来自一个 x86_64 平台下的 Linux 系统。我们能看到，host 字段的值为三元组 x86_64-unknown-linux-gnu，它包含了 CPU 架构 x86_64、供应商 unknown、操作系统 linux 和二进制接口 gnu。

Rust 编译器尝试为当前系统的三元组编译，并假定底层有一个类似于 Windows 或 Linux 的操作系统提供 C 语言运行环境，然而这将导致链接器错误。所以，为了避免这个错误，我们可以另选一个底层没有操作系统的运行环境。

这样的运行环境被称作裸机环境，例如目标三元组 riscv64imac-unknown-none-elf 描述了一个 RISC-V 64 位指令集的系统。我们暂时不需要了解它的细节，只需要知道这个环境底层没有操作系统，这是由三元组中的 none 描述的。要为这个目标编译，我们需要使用 rustup 添加它：

{% label %}运行命令{% endlabel %}
```bash
rustup target add riscv64imac-unknown-none-elf
```

这行命令将为目标下载一个标准库和 core 库。这之后，我们就能为这个目标成功构建独立式可执行程序了：

{% label %}运行命令{% endlabel %}
```bash
cargo build --target riscv64imac-unknown-none-elf
```

编译出的结果被放在了 `os/target/riscv64imac-unknown-none-elf/debug` 文件夹中。可以看到其中有一个名为 `os` 的可执行文件。不过由于它的目标平台是 RISC-V 64，我们暂时还不能通过我们的开发环境执行它。

由于我们之后都会使用 RISC-V 作为编译目标，为了避免每次都要加 `--target` 参数，我们可以使用 [cargo 配置文件](https://doc.rust-lang.org/cargo/reference/config.html)为项目配置默认的编译选项。

在 `os` 文件夹中创建一个 `.cargo` 文件夹，并在其中创建一个名为 `config` 的文件，在其中填入以下内容：

{% label %}os/.cargo/config{% endlabel %}
```toml
# 编译的目标平台
[build]
target = "riscv64imac-unknown-none-elf"
```

这指定了此项目编译时默认的目标。以后我们就可以直接使用 `cargo build` 来编译了。

至此，我们完成了在 RISC-V 64 位平台的二进制程序编译，后面我们将通过布局和代码的简单调整实现一个最简单的内核。