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
