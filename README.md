# uCore for riscv32 : uCore OS Labs on RISCV-32 (privileged spec 1.10)

ucore for riscv32 is a porting of [ucore_os_lab](https://github.com/chyyuu/ucore_os_lab.git) to RISC-V architecture (privileged spec 1.10). It's built on top of the [OpenSBI](https://github.com/riscv/opensbi), a supervisor execution environment for RISC-V systems.

# Quickstart

## Install toolchains

### 1. GCC

Install prebuilt RISC‑V
GCC Toolchain from SiFive:
* [Ubuntu](https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-8.2.0-2019.05.3-x86_64-linux-ubuntu14.tar.gz)
* [macOS](https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-8.2.0-2019.05.3-x86_64-apple-darwin.tar.gz)

```bash
$ export RISCV=/path/to/install/riscv/toolchain
$ export PATH=$RISCV/bin:$PATH
```

### 2. QEMU

Linux: build from source

```shell
$ sudo apt install libgtk-3-dev libsdl2-dev
$ wget https://download.qemu.org/qemu-4.0.0.tar.xz 
$ tar xJf qemu-4.0.0.tar.xz > /dev/null
$ cd qemu-4.0.0
$ ./configure --target-list=riscv32-softmmu
$ make
$ cp riscv32-softmmu/qemu-system-riscv32 $RISCV/bin
```
macOS: install from Homebrew
```shell
$ brew install qemu
```

## Building ucore

```bash
$ git clone -b riscv32-priv-1.10 --single-branch  https://github.com/chyyuu/ucore_os_lab
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

