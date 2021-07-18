# rCore-Tutorial-v3
rCore-Tutorial version 3.5. See the [Documentation in Chinese](https://rcore-os.github.io/rCore-Tutorial-Book-v3/).

## Overview

This project aims to show how to write an **Unix-like OS** running on **RISC-V** platforms **from scratch** in **[Rust](https://www.rust-lang.org/)** for **beginners** without any background knowledge about **computer architectures, assembly languages or operating systems**.

## Features

* Platform supported: `qemu-system-riscv64` simulator or dev boards based on [Kendryte K210 SoC](https://canaan.io/product/kendryteai) such as [Maix Dock](https://www.seeedstudio.com/Sipeed-MAIX-Dock-p-4815.html)
* OS
  * concurrency of multiple processes
  * preemptive scheduling(Round-Robin algorithm)
  * dynamic memory management in kernel
  * virtual memory
  * a simple file system with a block cache
  * an interactive shell in the userspace
* **only 4K+ LoC**
* [A detailed documentation in Chinese](https://rcore-os.github.io/rCore-Tutorial-Book-v3/) in spite of the lack of comments in the code(English version is not available at present)

## Run our project

TODO:

## Working in progress

Now we are still updating our project, you can find latest changes on branches `chX-dev` such as `ch1-dev`. We are intended to publish first release 3.5.0 after completing most of the tasks mentioned below.

### Completed

* [x] automatically clean up and rebuild before running our project on a different platform
* [x] fix `power` series application in early chapters, now you can find modulus in the output
* [x] use `UPSafeCell` instead of `RefCell` or `spin::Mutex` in order to access static data structures(now ch4 completed)
* [x] move `TaskContext` into `TaskControlBlock` instead of restoring it in place on kernel stack(since ch3), eliminating annoying `task_cx_ptr2`
* [x] replace `llvm_asm!` with `asm!`(now ch4 completed)

### Todo(High priority)

* [ ] adjust API of `UPSafeCell` so that it cannot be borrowed twice at a time
* [ ] bug fix: we should call `find_pte` rather than `find_pte_create` in `PageTable::unmap`
* [ ] add a new chapter about synchronization & mutual exclusion(uniprocessor only)
* [ ] give every non-zero process exit code an unique and clear error type
* [ ] effective error handling of mm module

### Todo(Low priority)

* [ ] rewrite practice doc and remove some inproper questions
* [ ] provide smooth debug experience at a Rust source code level
* [ ] format the code using official tools
* [ ] support Allwinner's RISC-V D1 chip

## Dependency

### Binaries

* rustc: 1.55.0-nightly (2f391da2e 2021-07-14)

* qemu: 5.0.0

* rustsbi-lib: 0.2.0-alpha.4

  rustsbi-qemu: d4968dd2

  rustsbi-k210: b689314e
### Crates

We will add them later.
