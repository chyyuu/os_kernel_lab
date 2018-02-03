# Quick Start

## Toolchain Installation

为了编译运行[bbl-ucore](https://github.com/ring00/bbl-ucore)，我们需要先配置RISC-V开发环境。我们已经有一份修改过的[riscv-tools](https://github.com/ring00/riscv-tools)供使用，输入以下命令快速安装工具链

```bash
$ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev
$ git clone https://github.com/ring00/riscv-tools.git
$ git submodule update --init --recursive
$ export RISCV=/path/to/install/riscv/toolchain
$ ./build-rv32g.sh
```

详细文档请查看[Installation Manual](https://github.com/ring00/riscv-tools#the-risc-v-gcc-toolchain-installation-manual)

## Compile and Run bbl-ucore

```bash
$ git clone https://github.com/ring00/bbl-ucore.git
$ git submodule update --init --recursive
```

现在我们可以到各个实验目录下执行`make spike`命令来编译并使用[Spike](https://github.com/riscv/riscv-isa-sim)模拟器运行实验。若想一次性编译全部实验，请执行

```bash
$ cd labcodes
$ ./gccbuildall.sh
```
