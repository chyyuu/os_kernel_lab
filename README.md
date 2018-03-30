# uCore for riscv64 : uCore OS Labs on RISCV-64 (privileged spec 1.10)

ucore for riscv64 is a porting of [ucore_os_lab](https://github.com/chyyuu/ucore_os_lab.git) to RISC-V architecture (privileged spec 1.10). It's built on top of the Berkeley Boot Loader, [`bbl`](https://github.com/riscv/riscv-pk.git), a supervisor execution environment for RISC-V systems.

**NOTE: This branch is still on developing, please see dosc/ucore_rv64_porting.md for more details. **

# Quickstart

## Installing riscv-tools

You'll need a forked verison of [riscv-tools](https://github.com/riscv/riscv-tools) to build the toolchain for RV64. Excute the following commands to get started quickly. (tested in ubuntu 16.04 x86-64)

### 0. setenv
```bash
$ export RISCV=/path/to/install/riscv/toolchain
$ export PATH=$RISCV/bin:$PATH
```

### 1. build gcc/gdb tools (64bit) 
```bash
$ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev
$ git clone https://github.com/riscv/riscv-tools.git
$ cd riscv-tools
$ git submodule update --init --recursive
$ ./build.sh
# 编译完成后，确保gcc版本为7.2.0
$ cd ..
```

### 2. build qemu (64bit)

```shell
$ sudo apt install libgtk-3-dev
$ sudo apt install libsdl2-dev
$ cd riscv-tools/riscv-gnu-toolchain/riscv-qemu
$ ./configure --target-list=riscv64-softmmu
$ make
$ cp riscv64-softmmu/qemu-system-riscv64 $RISCV/bin
```



See [Installation Manual](https://github.com/ring00/riscv-tools#the-risc-v-gcc-toolchain-installation-manual) for details.

## Building ucore

```bash
$ git clone -b riscv64-priv-1.10 --single-branch  https://gitee.com/shzhxh/ucore_os_lab.git
```

### 1. build ucore (64bit)

To build all projects at once, run the following commands

```bash
$ cd labcodes_answer
$ ./gccbuildall.sh
# lab1~lab4 is OK, lab5 has some mistake
```



# Labs info

```
lab0: preparing
lab1: boot/protect mode/stack/interrupt
lab2: physical memory management
lab3: virtual memory management
lab4: kernel thread management
lab5: user process management
lab6: scheduling
lab7: mutex/sync
lab8: filesystem
```

# Read the Docs

Detailed documentation can be found in docs directory.

# Maintainers
- Yu Chen: yuchen AT tsinghua.edu.cn
- Yong, Xiang: xyong@tsinghua.edu.cn
- Mao, Junjie: eternal.n08@gmail.com
- Wei Zhang:  zhangwei15 AT mails.tsinghua.edu.cn

