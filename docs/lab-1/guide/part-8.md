## 使用 Qemu 运行内核

### 安装模拟器 Qemu

如果你在使用 Linux (Ubuntu) ，需要到 Qemu 官方网站下载源码并自行编译，因为 Ubuntu 自带的软件包管理器 `apt` 中的 Qemu 的版本过低无法使用。参考命令如下：

```sh
$ wget https://download.qemu.org/qemu-4.1.1.tar.xz
$ tar xvJf qemu-4.1.1.tar.xz
$ cd qemu-4.1.1
$ ./configure --target-list=riscv32-softmmu,riscv64-softmmu
$ make -j
$ export PATH=$PWD/riscv32-softmmu:$PWD/riscv64-softmmu:$PATH
```

可查看[更详细的安装和使用命令][riscv-qemu]。同时，我们在每次开机之后要使用此命令来允许模拟器过量使用内存（不是必须的），否则无法正常使用 Qemu：

```bash
$ sudo sysctl vm.overcommit_memory=1
```

如果你在使用 macOS，只需要 Homebrew 一个命令即可：

```sh
$ brew install qemu
```

最后确认一下 Qemu 已经安装好，且版本在 4.1.0 以上：

```bash
$ qemu-system-riscv64 --version
QEMU emulator version 4.1.1
Copyright (c) 2003-2019 Fabrice Bellard and the QEMU Project developers
```

### 使用 OpenSBI

新版 Qemu 中内置了 [OpenSBI][opensbi] `firrmwire`（固件），它主要负责在操作系统运行前的硬件初始化和加载操作系统的功能。我们使用以下命令尝试运行一下：

```bash
$ qemu-system-riscv64 \
  --machine virt \
  --nographic \
  --bios default

OpenSBI v0.4 (Jul  2 2019 11:53:53)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : QEMU Virt Machine
Platform HART Features : RV64ACDFIMSU
Platform Max HARTs     : 8
Current Hart           : 0
Firmware Base          : 0x80000000
Firmware Size          : 112 KB
Runtime SBI Version    : 0.1

PMP0: 0x0000000080000000-0x000000008001ffff (A)
PMP1: 0x0000000000000000-0xffffffffffffffff (A,R,W,X)
```

可以看到我们已经在 `qemu-system-riscv64` 模拟的 `virt machine` 硬件上将 `OpenSBI` 这个 `firmwire` 跑起来了。Qemu 可以使用 `Ctrl+a` 再按下 `x` 退出。

> **[info] `OpenSBI`的内部实现**
> 如果对 `OpenSBI` 的内部实现感兴趣，可以看看[RISCV OpenSBI Deep_Dive 介绍文档][riscv_opensbi_deep_dive]。

### 加载内核镜像

为了确信我们已经跑起来了内核里面的代码，我们最好在 `rust_main` 里面加一点东西。

```rust
// src/main.rs

#![feature(asm)]

// 在屏幕上输出一个字符，目前我们先不用了解其实现原理
pub fn console_putchar(ch: u8) {
    let ret: usize;
    let arg0: usize = ch as usize;
    let arg1: usize = 0;
    let arg2: usize = 0;
    let which: usize = 1;
    unsafe {
        asm!("ecall"
             : "={x10}" (ret)
             : "{x10}" (arg0), "{x11}" (arg1), "{x12}" (arg2), "{x17}" (which)
             : "memory"
             : "volatile"
        );
    }
}

#[no_mangle]
extern "C" fn rust_main() -> ! {
    // 在屏幕上输出 "OK\n" ，随后进入死循环
    console_putchar(b'O');
    console_putchar(b'K');
    console_putchar(b'\n');
    loop {}
}
```

这样，如果我们将内核镜像加载完成后，屏幕上出现了 OK ，就说明我们之前做的事情没有问题。如果想进一步了解上面例子中的内联汇编(**"asm!"**)，请参考 [附录：内联汇编](../appendix/inline_asm.md) 。

现在我们生成内核镜像要通过多条命令来完成，我们通过 `Makefile` 来简化这一过程。

```makefile
# Makefile

target := riscv64imac-unknown-none-elf
mode := debug
kernel := target/$(target)/$(mode)/os
bin := target/$(target)/$(mode)/kernel.bin

objdump := rust-objdump --arch-name=riscv64
objcopy := rust-objcopy --binary-architecture=riscv64

.PHONY: kernel build clean qemu run env

env:
	cargo install cargo-binutils
	rustup component add llvm-tools-preview rustfmt
	rustup target add $(target)

kernel:
	cargo build

$(bin): kernel
	$(objcopy) $(kernel) --strip-all -O binary $@

asm:
	$(objdump) -d $(kernel) | less

build: $(bin)

clean:
	cargo clean

qemu: build
	qemu-system-riscv64 \
		-machine virt \
		-nographic \
		-bios default \
		-device loader,file=$(bin),addr=0x80200000

run: build qemu

```

这里我们通过参数 `-device` 来将内核镜像加载到 Qemu 中，我们指定了内核镜像文件，但这个地址 `0x80200000` 又是怎么一回事？我们目前先不用在意这些细节，等后面会详细讲解。

于是，我们可以使用 `make run` 来用 Qemu 加载内核镜像并运行。匆匆翻过一串长长的 OpenSBI 输出，我们看到了 `OK` ！于是历经了千辛万苦我们终于将我们的内核跑起来了！

没有看到 OK ？迄今为止的代码可以在[这里][code]找到，请参考。

### `virt machine`硬件配置

> **[info] 扩展内容**

也许有同学对`qemu-system-riscv64`模拟的`virt machine`计算机的硬件配置感兴趣，那么通过如下命令，可以看到到当前`virt machine`的硬件配置信息：

```
$ sudo apt install device-tree-compiler #安装device tree编译器/解释器 dtc
$ qemu-system-riscv64 -machine virt -machine dumpdtb=riscv64-virt.dtb -bios default #生成virt machine计算机的二进制device tree信息
$ dtc -I dtb -O dts -o riscv64-virt.dts riscv64-virt.dtb #转换为文本格式的device tree信息
$ more riscv64-virt.dts #显示virt machine计算机的硬件配置信息
```

如果同学对`qemu-system-riscv64`模拟的`virt machine`计算机硬件（包括外设）配置的具体实现代码感兴趣，那么可看看[qemu riscv 的 virt machine 实现](https://github.com/qemu/qemu/blob/master/hw/riscv/virt.c)。

下一节我们实现格式化输出来使得我们后续能够更加方便的通过输出来进行内核调试。