# 环境部署

在开展实验之前，我们需要根据不同的平台提前安装相关依赖的软件包，具体需要的软件包如下：
- Rust 工具链
  - Rust 版本管理工具：rustup
  - Rust 软件包管理工具：cargo
  - Rust 编译器：rustc
  - 等等
- 虚拟机软件：qemu （版本至少支持 RISC-V 64）

具体安装的方法在不同平台上安装方式类似，但也有细微差别，后面会有具体说明。

<!-- TODO: Normal Windows -->

## 安装 qemu
根据不同平台，我们分为下面 2 个部分来介绍。

### macOS
在 macOS 中，我们可以直接打开命令行用 Homebrew 软件包管理器来安装最新版 qemu 和其依赖：

```bash
brew install qemu
```

### Linux/Windows WSL
在 Linux 中，由于很多软件包管理器的默认软件源中包含的 qemu 版本过低，这里**推荐**的方式是我们自己手动从源码编译安装：

```bash
# 下载源码包 （如果下载速度过慢可以把地址替换为我们提供的地址：TODO）
wget https://download.qemu.org/qemu-4.2.0.tar.xz
# 解压
tar xvJf qemu-4.2.0.tar.xz
# 编译安装
cd qemu-4.2.0
./configure --target-list=riscv32-softmmu,riscv64-softmmu
make -j$(nproc)
sudo make install
```

如果在进行 `configure` 时遇到软件包依赖的问题（以 Ubuntu 系统举例）：
- 出现 `ERROR: pkg-config binary 'pkg-config' not found` 时，可以通过 `sudo apt-get install pkg-config` 安装；
- 出现 `ERROR: glib-2.48 gthread-2.0 is required to compile QEMU` 时，可以通过 `sudo apt-get install libglib2.0-dev` 安装；
- 出现 `ERROR: pixman >= 0.21.8 not present` 时，可以通过 `sudo apt-get install libpixman-1-dev` 安装。

如果有其他问题，请针对不同操作系统在软件包管理器中查找并安装依赖。

当然如果你可以找到包含较新版本的 qemu 的软件包源，**也可以**通过软件包管理器直接安装：

```bash
# Ubuntu/Debian/Windows WSL
sudo apt-get install qemu

# CentOS/Fedora/RedHat/SUSE
sudo yum install qemu
```

### 完成后
安装完成后可以用：

```bash
qemu-system-riscv64 --version
```

命令检查是否成功安装我们需要的 RISC-V 64 虚拟器并检查版本是否至少是 4.1.0。

## 安装 Rust 工具链
首先安装 Rust 版本管理器 rustup 和 Rust 包管理器 cargo，这里我们用官方的安装脚本来安装：

```bash
curl https://sh.rustup.rs -sSf | sh
```

如果通过官方的脚本下载失败了，可以在浏览器的地址栏中输入 https://sh.rustup.rs 来下载脚本，在本地运行即可。

如果官方的脚本在运行时出现了网络速度较慢的问题，**可选地**可以通过修改 rustup 的镜像地址（修改为中国科学技术大学的镜像服务器）来加速：

```bash
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
curl https://sh.rustup.rs -sSf | sh
```

**或者**也可以通过在运行前设置命令行中的科学上网代理来实现：
```bash
# e.g. Shadowsocks 代理
export https_proxy=http://127.0.0.1:1080
export http_proxy=http://127.0.0.1:1080
export ftp_proxy=http://127.0.0.1:1080
```

安装完成后，**最好**我们也可以把软件包管理器 cargo 所用的软件包镜像地址 crates.io 也换成中国科学技术大学的镜像服务器来加速。我们打开（如果没有就新建）`~/.cargo/config` 文件，并把内容修改为：
```bash
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"
replace-with = 'ustc'
[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"
```

## 安装完成后
在相关软件包安装完成之后，只需要下面的命令，就可以把整个教程完成之后的 rCore 系统在你的系统上运行起来：
```bash
# 克隆仓库并编译运行
git clone TODO
cd rCore-Tutorial
git checkout master

# 编译运行
make run

# 如果一切正常，则 qemu 模拟的 RISC-V 64 处理器将输出
TODO
```

需要说明的是，Rust 包含 stable、beta 和 nightly 三个版本。默认情况下我们安装的是 stable 稳定版。由于在编写操作系统时需要使用 Rust 的一些不稳定的实验功能，因此我们使用 nightly 每日构建版。

但是，由于官方不保证 nightly 版本的 ABI 稳定性，也就意味着今天写的代码用未来的 nightly 可能无法编译通过，因此一般在使用 nightly 时应该锁定一个日期。

所以我们的工作目录下会有一个名为 `rust-toolchain` 的文件（无后缀名），在其中有所需的工具链版本：

```
nightly-2020-03-06
```

在第一次编译项目时，rustup 会自动去下载对应版本的工具链。今后所有在这个目录或其子目录下使用 Rust 时都会自动切换到这个版本的工具链。随着日后的更新，后面的日期可能会变化，请以 Github 仓库上的版本为准。