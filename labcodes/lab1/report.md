# Lab 1

## 知识点

这些是与本实验有关的原理课的知识点：

* 系统启动
* x86的中断和异常机制
* 用中断实现系统调用
* 中断描述符表

此外，本实验还涉及如下知识点：

* 硬盘驱动程序
* ELF文件格式

遗憾的是，如下知识点在原理课中很重要，但本次实验没有很好的对应：

无

## 练习1

使用`make "V="`命令得到如下生成ucore.img磁盘镜像的过程，具体的命令及它们的输出见`make_cmds.txt`。

### 1. 编译生成内核代码

命令为`gcc -I... -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc -fno-stack-protector -c kern/***.c -o obj/kern/***.o`。

该条命令：

1. `-I...`设定了引用文件查找目录
2. `-fno-builtin -nostdinc`关闭了内建的库
3. `-Wall`开启所有警告
4. `-ggdb -gstabs`添加调试信息
5. `-m32`生成32位代码
6. `-fno-stack-protector`不生成栈保护代码
7. 最后，把`kern`下的.c代码生成到`obj/kern`的.o文件

### 2. 链接生成内核映像 

命令为`ld -m elf_i386 -nostdlib -T tools/kernel.ld -o bin/kernel obj/***.o`。

该条命令：

1. `-m elf_i386`生成32位ELF映像
2. `-nostdlib`关闭了内建的库
3. `-T tools/kernel.ld`使用链接器脚本`tools/kernel.ld`，这个脚本描述了代码和数据在内存中的布局，以及设定了内核入口地址
4. `-o bin/kernel obj/***.o`把`obj`下的.o文件链接生成`bin/kernel`文件

### 3. 编译生成bootloader代码

命令和含义几乎与1.完全类似。

### 4. 链接生成bootloader映像

命令为`ld -m elf_i386 -nostdlib -N -e start -Ttext 0x7C00 obj/boot/***.o -o obj/bootblock.o`。

该条命令：

1. `-m elf_i386`生成32位ELF映像
2. `-nostdlib`关闭了内建的库
3. `-N`设置代码段和数据段都可读可写，关闭动态链接
4. `-e start`指定入口点符号为`start`
5. `-Ttext 0x7C00`设置代码段起始地址为`0x7c00`
6. `obj/boot/***.o -o obj/bootblock.o`把`obj/boot/`下的.o文件链接生成`obj/bootblock.o`文件

### 5. 生成bootloader二进制代码

命令为`objcopy -S -O binary obj/bootblock.o obj/bootblock.out`。

该条命令：

1. `-S`不生成重定位信息和调试信息
2. `-O binary`拷贝二进制代码
3. `obj/bootblock.o obj/bootblock.out`将ELF格式的`obj/bootblock.o`文件中的代码段拷贝到`obj/bootblock.out`

### 6. 生成启动扇区

为生成启动扇区，先编译生成`tools/sign.c`工具。该工具检查`obj/bootblock.out`文件的大小是否超过510字节，然后利用这个文件生成启动扇区`bin/bootblock`。启动扇区的特点见下。

### 7. 初始化磁盘镜像文件

命令为`dd if=/dev/zero of=bin/ucore.img count=10000`。

该条命令：

1. `if=/dev/zero`从全零的一个设备文件读取
2. `of=bin/ucore.img`写入到`bin/ucore.img`
3. `count=10000`共10000个扇区（共5120000字节）

### 8. 将启动扇区写入镜像文件

命令为`dd if=bin/bootblock of=bin/ucore.img conv=notrunc`。

该条命令：

1. `if=bin/bootblock`从6.生成的启动扇区文件读取
2. `of=bin/ucore.img`写入到`bin/ucore.img`
3. `conv=notrunc`不将`bin/ucore.img`文件清空

### 9. 将内核映像写入镜像文件

命令为`dd if=bin/kernel of=bin/ucore.img seek=1 conv=notrunc`。

该条命令：

1. `if=bin/kernel`从2.生成的内核映像文件读取
2. `of=bin/ucore.img`写入到`bin/ucore.img`
3. `seek=1`写入时，从第1扇区开始写入
4. `conv=notrunc`不将`bin/ucore.img`文件清空

### 启动扇区的特点

能够被BIOS识别的启动扇区有如下特点：

1. 符合扇区基本要求，大小512字节
2. 最后两个字节，即第510和511个字节，分别为`0x55 0xAA`；若表示为一个16位的字，则为`0xAA55`（小端序）

若是有分区信息，还将有分区表。

## 练习2

首先，将`gdbinit`脚本中如下两行**去掉**，使得运行`make debug`时不自动开始运行。

```
break kern_init
continue
```

然后运行`make debug`开始实验。

此时，QEMU停在`0xfffffff0`，使用`i r`命令得到，cs=`0xf000`，eip=`0xfff0`。GDB对于段机制的处理不是很好，所以需要手动指定物理地址来查看相应代码。

执行`x/i 0xfffffff0`可以得到开机后执行的第一条指令：`ljmp $0x3630, $0xf000e05b`。指令很奇怪，这是由于没有设置指令集为16位，GDB默认是32位，导致反汇编错误，使用`set arch i8086`设置之后重新`x/i 0xfffffff0`，得到正确结果：`ljmp $0xf000, $0xe05b`。

执行几次`si`，查看指令的执行情况，发现果真跳转到`0xfe05b`开始执行了。

执行`b *0x7c00`在`0x7c00`处设下断点，执行`c`使得QEMU继续运行，之后发现在`0x7c00`暂停了，断点有效。

执行`x/10i 0x7c00`查看反汇编，发现与`bootasm.S`一致，但与`bootblock.asm`不太一致。这是由于反汇编生成`bootblock.asm`时，使用的是32位指令集。

现在开始调试设置A20的代码。

执行`b *0x7c0a`在`0x7c0a`设下断点，然后使用`si`单步执行，期间用`layout`切换格局，可以同时查看汇编代码以及寄存器的值。

## 练习3

系统加电时，处理器处于实模式状态，为了让它进入保护模式使用完整的32位地址线以及实现更多的保护功能，需要进行一些准备，然后将CR0中PE位置位，最后处理器开始执行保护模式下32位代码。

详细操作描述如下：

### 1. 开启第20位地址线（A20）

由于历史原因，进入保护模式之前，需要开启第20位地址线（下面简称A20）。

`bootasm.S`中开始A20的方法是：

1. 等待直到8042不忙
2. 向8042控制端口写入写P2端口命令（`0xd1`）
3. 等待直到8042不忙
4. 向8042数据端口写入`0xdf`来打开A20

值得注意，随着时代的发展，开启A20的方法千变万化，这只是其中的一种。

### 2. 配置全局描述符表（GDT）

由于本实验弱化对于分段机制的使用，GDT及其基址和界限的描述可以写死在代码中。GDT内容有三项，空、代码段以及数据段。然后，用`lgdt`载入GDT的基址和界限即可。注意，GDT需要4字节对齐。

### 3. 开启保护模式

将CR0的PE位（第0位）置1即可。注意，置1后，处理器并未立即开始执行32位代码。

### 4. 开始执行32位代码

使用远跳转指令`ljmp`，将代码段寄存器`cs`设置为新的值（代码段选择子），从而真正开始32位保护模式。

由于2.配置GDT时将代码段设置为恒等映射，同时未开启分页机制，逻辑地址和物理地址直接相等，跳转目标就是下一条指令的地址。

注意跳转后还应该将各个数据段寄存器也设置为新的值（数据段选择子）。