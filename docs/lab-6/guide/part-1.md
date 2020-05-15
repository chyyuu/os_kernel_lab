## 构建用户程序框架

接下来我们要做的工作，和实验准备中为操作系统『去除依赖』的工作十分类似：我们需要为用户程序提供一个类似的没有运行时依赖的环境。这里我们会快速梳理一遍我们为用户程序进行的流程。

### 建立 crate

我们在与 `os` 的旁边建立一个 `user` crate。此时，我们移除默认的 `main.rs`，而是在 `src` 目录下建立 `lib` 子目录，在其中存放的源文件会被编译成多个单独的执行文件。

```bash
cargo new --bin user
```

```
rCore-Tutorial
  - os
  - user
    - src
      - bin
        - hello_world.rs
      - lib.rs
    - Cargo.toml
```

### 基础框架搭建

和操作系统一样，我们需要为用户程序移除 std 依赖，并且补充一些必要的功能。

#### `lib.rs`

- `#![no_std]` 移除标准库
- `#![feature(...)]` 开启一些不稳定的功能
- `#[global_allocator]` 使用库来实现堆栈动态内存分配
- `#[panic_handler]` panic 时终止

#### 其他文件

- `.cargo/config` 设置编译目标为 RISC-V 64
- `console.rs` 实现 `print!` `println!` 宏
