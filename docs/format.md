## 记号约定

### 一些标准的架构、软件名词写法
- 语言相关
  - Rust
  - C
  - C++
- 教程
  - rCore-Tutorial
- 操作系统相关
  - uCore
  - rCore
  - Linux
  - macOS
  - Windows
  - Ubuntu
- 架构相关
  - x86_64
  - RISC-V 64
- 其他一些名词
  - ABI
  - GitHub
  - Bootloader
- Rust 相关
  - rustup
  - cargo
  - rustc
  - Panic
- 其他软件
  - qemu
  - Homebrew

### 书写格式

- 在数字、英文、独立的标点或记号两侧的中文之间要加空格，如：

  - 安装 qemu
  - 分为 2 个部分

- 命令、宏名、类型名、函数名、变量名、编译选项、路径和文件名需要使用 `记号`

- 行内命令或运行输出引用使用 \`\` 记号，并在两侧加入空格，如：

  - `cargo run`
  - 出现 `ERROR: pkg-config binary 'pkg-config' not found` 时

- 行间命令使用 \`\`\` 记号并加入语言记号：

  - 命令使用 bash 记号

  - Rust 语言使用 rust 记号

  - cargo 的一些配置使用 toml 记号

  - 如何命令只是命令，则不需要 $ 记号（方便同学复制），如：

    ```bash
    echo "Hello, world."
    ```

  - 如果在展示一个命令带来的输出效果，需要加入 $ 记号表示一个命令的开始，如：

    ```bash
    $ echo "Hello, world."
    Hello, world.
    ```

- 粗体使用 \*\* **粗体** \*\* 记号

  - 一些重要的概念最好进行加粗

- 斜体使用 \* *斜体* \* 记号，而不要混合使用 \_ _Italic_ \_ 记号

- 在正式的段落中要加入标点符号，在 - 记号开始的列表中的表项不加入标点符号

- 在 / 记号两侧添加空格，如：

  - Linux / Windows WSL

- 中文名词的英文解释用小写（除非是人名等等），如：

  - 裸机（bare metal）

- 只要是主体是中文的段落，括号统一使用中文括号（），如果主体是英文则使用英文括号 ()

  - 值得注意的是中文括号两侧本来就会又留白，这里不会在括号两侧加入空格
  - 英文空格两侧最好加上空格

- 在文档中引用成段的代码时，需要填写上文件的相对路径，如：

  ```rust
  src/sbi.rs
  
  /// 向控制台输出一个字符
  ///
  /// 需要注意我们不能直接使用 Rust 中的 char 类型
  pub fn console_putchar(c: usize) {
      sbi_call(SBI_CONSOLE_PUTCHAR, c, 0, 0);
  }
  ```

### 小节格式

- 章节的标题为使用 `#` 一级标题，后面的子标题依次加级别
- 小节的标题统一使用 `##` 二级标题，后面的子标题依次加级别