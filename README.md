# uCore for riscv32 : uCore OS Labs on RISCV-32 (privileged spec 1.10)

ucore for riscv32 is a porting of [ucore_os_lab](https://github.com/chyyuu/ucore_os_lab.git) to RISC-V architecture (privileged spec 1.10). It's built on top of the Berkeley Boot Loader, [`bbl`](https://github.com/riscv/riscv-pk.git), git commit id e5846a2,  a supervisor execution environment for RISC-V systems.

# Quickstart

## Installing riscv-tools

You'll need a forked verison of [riscv-tools](https://github.com/riscv/riscv-tools) to build the toolchain for RV32. Excute the following commands to get started quickly. (tested in ubuntu 16.04 x86-64, 17.10 x86-64)

### 0. setenv
```bash
$ export RISCV=/path/to/install/riscv/toolchain
$ export PATH=$RISCV/bin:$PATH
```

### 1. build gcc/gdb tools 
```bash
$ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev
$ git clone https://github.com/riscv/riscv-tools.git
$ cd riscv-tools
$ git submodule update --init --recursive
$ ./build-rv32g.sh
$ cd ..
```

### 2. build qemu

```
$ git clone https://github.com/riscv/riscv-qemu.git
$ cd riscv-qemu
$ ./configure --target-list=riscv32-softmmu
$ make
$ cp riscv32-softmmu/qemu-system-riscv32 $RISCV/bin
$ cd ..
```

See [Installation Manual](https://github.com/ring00/riscv-tools#the-risc-v-gcc-toolchain-installation-manual) for details.

## Building ucore

```bash
$ git clone -b riscv-priv-1.10 --single-branch  https://github.com/chyyuu/ucore_os_lab.git
$ git 
```

To build all projects at once, run the following commands

```bash
$ cd labcodes_answer
$ ./gccbuildall.sh
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
  - https://github.com/ring00/bbl-ucore
  - https://ring00.github.io/bbl-ucore/#/

