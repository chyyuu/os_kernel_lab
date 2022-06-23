# rCore-Tutorial-v3
rCore-Tutorial version 3.6. See the [Documentation in Chinese](https://rcore-os.github.io/rCore-Tutorial-Book-v3/).

rCore-Tutorial API Docs.  See the [API Docs of Ten OSes ](#OS-API-DOCS)

Official QQ group number: 735045051

## news
- 23/06/2022: Version 3.6.0 is on the way! Now we directly update the code on chX branches, please periodically check if there are any updates.

## Overview

This project aims to show how to write an **Unix-like OS** running on **RISC-V** platforms **from scratch** in **[Rust](https://www.rust-lang.org/)** for **beginners** without any background knowledge about **computer architectures, assembly languages or operating systems**.

## Features

* Platform supported: `qemu-system-riscv64` simulator or dev boards based on [Kendryte K210 SoC](https://canaan.io/product/kendryteai) such as [Maix Dock](https://www.seeedstudio.com/Sipeed-MAIX-Dock-p-4815.html)
* OS
  * concurrency of multiple processes each of which contains mutiple native threads
  * preemptive scheduling(Round-Robin algorithm)
  * dynamic memory management in kernel
  * virtual memory
  * a simple file system with a block cache
  * an interactive shell in the userspace
* **only 4K+ LoC**
* [A detailed documentation in Chinese](https://rcore-os.github.io/rCore-Tutorial-Book-v3/) in spite of the lack of comments in the code(English version is not available at present)

## Prerequisites

### Install Rust

See [official guide](https://www.rust-lang.org/tools/install).

Install some tools:

```sh
$ rustup target add riscv64gc-unknown-none-elf
$ cargo install cargo-binutils --vers =0.3.3
$ rustup component add llvm-tools-preview
$ rustup component add rust-src
```

### Install Qemu

Here we manually compile and install Qemu 7.0.0. For example, on Ubuntu 18.04:

```sh
# install dependency packages
$ sudo apt install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev \
              gawk build-essential bison flex texinfo gperf libtool patchutils bc \
              zlib1g-dev libexpat-dev pkg-config  libglib2.0-dev libpixman-1-dev git tmux python3 python3-pip
# download Qemu source code
$ wget https://download.qemu.org/qemu-7.0.0.tar.xz
# extract to qemu-7.0.0/
$ tar xvJf qemu-7.0.0.tar.xz
$ cd qemu-7.0.0
# build
$ ./configure --target-list=riscv64-softmmu,riscv64-linux-user
$ make -j$(nproc)
```

Then, add following contents to `~/.bashrc`(please adjust these paths according to your environment):

```
export PATH=$PATH:/home/shinbokuow/Downloads/built/qemu-7.0.0
export PATH=$PATH:/home/shinbokuow/Downloads/built/qemu-7.0.0/riscv64-softmmu
export PATH=$PATH:/home/shinbokuow/Downloads/built/qemu-7.0.0/riscv64-linux-user
```

Finally, update the current shell:

```sh
$ source ~/.bashrc
```

Now we can check the version of Qemu:

```sh
$ qemu-system-riscv64 --version
QEMU emulator version 7.0.0
Copyright (c) 2003-2020 Fabrice Bellard and the QEMU Project developers
```

### Install RISC-V GNU Embedded Toolchain(including GDB)

Download the compressed file according to your platform From [Sifive website](https://www.sifive.com/software)(Ctrl+F 'toolchain').

Extract it and append the location of the 'bin' directory under its root directory to `$PATH`.

For example, we can check the version of GDB:

```sh
$ riscv64-unknown-elf-gdb --version
GNU gdb (SiFive GDB-Metal 10.1.0-2020.12.7) 10.1
Copyright (C) 2020 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
```

### Install serial tools(Optional, if you want to run on K210)

```sh
$ pip3 install pyserial
$ sudo apt install python3-serial
```

## Run our project

### Qemu

```sh
$ git clone https://github.com/rcore-os/rCore-Tutorial-v3.git
$ cd rCore-Tutorial-v3/os
$ make run
```

After outputing some debug messages, the kernel lists all the applications available and enter the user shell:

```
/**** APPS ****
mpsc_sem
usertests
pipetest
forktest2
cat
initproc
race_adder_loop
threads_arg
race_adder_mutex_spin
race_adder_mutex_blocking
forktree
user_shell
huge_write
race_adder
race_adder_atomic
threads
stack_overflow
filetest_simple
forktest_simple
cmdline_args
run_pipe_test
forktest
matrix
exit
fantastic_text
sleep_simple
yield
hello_world
pipe_large_test
sleep
phil_din_mutex
**************/
Rust user shell
>> 
```

You can run any application except for `initproc` and `user_shell` itself. To run an application, just input its filename and hit enter. `usertests` can run a bunch of applications, thus it is recommended.

Type `Ctrl+a` then `x` to exit Qemu.

### K210

Before chapter 6, you do not need a SD card:

```sh
$ git clone https://github.com/rcore-os/rCore-Tutorial-v3.git
$ cd rCore-Tutorial-v3/os
$ make run BOARD=k210
```

From chapter 6, before running the kernel, we should insert a SD card into PC and manually write the filesystem image to it:

```sh
$ cd rCore-Tutorial-v3/os
$ make sdcard
```

By default it will overwrite the device `/dev/sdb` which is the SD card, but you can provide another location. For example, `make sdcard SDCARD=/dev/sdc`.

After that, remove the SD card from PC and insert it to the slot of K210. Connect the K210 to PC and then:

```sh
$ git clone https://github.com/rcore-os/rCore-Tutorial-v3.git
$ cd rCore-Tutorial-v3/os
$ make run BOARD=k210
```

Type `Ctrl+]` to disconnect from K210.

## Rustdoc

Currently it can only help you view the code since only a tiny part of the code has been documented.

You can open a doc html of `os` using `cargo doc --no-deps --open` under `os` directory.

### OS-API-DOCS
The API Docs for Ten OS
1. [Lib-OS API doc](https://learningos.github.io/rCore-Tutorial-v3/ch1/os/index.html)
1. [Batch-OS API doc](https://learningos.github.io/rCore-Tutorial-v3/ch2/os/index.html)
1. [MultiProg-OS API doc](https://learningos.github.io/rCore-Tutorial-v3/ch3-coop/os/index.html)
1. [TimeSharing-OS API doc](https://learningos.github.io/rCore-Tutorial-v3/ch3/os/index.html)
1. [AddrSpace-OS API doc](https://learningos.github.io/rCore-Tutorial-v3/ch4/os/index.html)
1. [Process-OS API doc](https://learningos.github.io/rCore-Tutorial-v3/ch5/os/index.html)
1. [FileSystem-OS API doc](https://learningos.github.io/rCore-Tutorial-v3/ch6/os/index.html)
1. [IPC-OS API doc](https://learningos.github.io/rCore-Tutorial-v3/ch7/os/index.html)
1. [SyncMutex-OS API doc](https://learningos.github.io/rCore-Tutorial-v3/ch8/os/index.html)
1. [IODevice-OS API doc](https://learningos.github.io/rCore-Tutorial-v3/ch9/os/index.html)

## Working in progress

Our first release 3.6.0 (chapter 1-9) has been published, and we are still working on it.

* chapter 9: need more descripts about different I/O devices

Here are the updates since 3.5.0:

### Completed

* [x] automatically clean up and rebuild before running our project on a different platform
* [x] fix `power` series application in early chapters, now you can find modulus in the output
* [x] use `UPSafeCell` instead of `RefCell` or `spin::Mutex` in order to access static data structures and adjust its API so that it cannot be borrowed twice at a time(mention `& .exclusive_access().task[0]` in `run_first_task`)
* [x] move `TaskContext` into `TaskControlBlock` instead of restoring it in place on kernel stack(since ch3), eliminating annoying `task_cx_ptr2`
* [x] replace `llvm_asm!` with `asm!`
* [x] expand the fs image size generated by `rcore-fs-fuse` to 128MiB
* [x] add a new test named `huge_write` which evaluates the fs performance(qemu\~500KiB/s k210\~50KiB/s)
* [x] flush all block cache to disk after a fs transaction which involves write operation
* [x] replace `spin::Mutex` with `UPSafeCell` before SMP chapter
* [x] add codes for a new chapter about synchronization & mutual exclusion(uniprocessor only)
* [x] bug fix: we should call `find_pte` rather than `find_pte_create` in `PageTable::unmap`
* [x] clarify: "check validity of level-3 pte in `find_pte` instead of checking it outside this function" should not be a bug
* [x] code of chapter 8: synchronization on a uniprocessor
* [x] switch the code of chapter 6 and chapter 7
* [x] support signal mechanism in chapter 7/8(only works for apps with a single thread)
* [x] Add boards/ directory and support rustdoc, for example you can use `cargo doc --no-deps --open` to view the documentation of a crate
* [x] code of chapter 9: device drivers based on interrupts, including UART, block, keyboard, mouse, gpu devices
* [x] add CI autotest and doc in github 
### Todo(High priority)

* [ ] review documentation, current progress: 8/9
* [ ] use old fs image optionally, do not always rebuild the image
* [ ] shell functionality improvement(to be continued...)
* [ ] give every non-zero process exit code an unique and clear error type
* [ ] effective error handling of mm module
* [ ] add more os functions for understanding os conecpts and principles
### Todo(Low priority)

* [ ] rewrite practice doc and remove some inproper questions
* [ ] provide smooth debug experience at a Rust source code level
* [ ] format the code using official tools

### Crates

We will add them later.
