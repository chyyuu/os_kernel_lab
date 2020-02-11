# Lab 1 Report
## 要求
lab1中包含一个bootloader和一个OS。bootloader可以切换到X86保护模式，能够读磁盘并加载ELF执行文件格式、显示字符。OS只是一个可以处理时钟中断和显示字符的幼儿园级别OS。

- 基于markdown格式来完成，以文本方式为主。
- 填写各个基本练习中要求完成的报告内容
- 完成实验后，请分析[ucore_os_lab](https://github.com/chyyuu/ucore_os_lab)中提供的参考答案，**请在实验报告中说明你的实现与参考答案的区别**
- 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义、关系、差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
- 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

## 练习一：理解通过make生成执行文件的过程
本练习后，要能回答下面的问题：
1. 操作系统镜像文件`ucore.img`是如何一步一步生成的？**需要比较详细地解释Makefile中每一条相关命令和命令参数的含义，以及说明命令导致的结果。**
2. 一个被系统认为是符合规范的**硬盘主引导扇区的特征是什么**？

### ucore.img的生成过程
ucore.img由Makefile中下面的配置生成：
```shell
$(bootblock): $(call toobj,$(bootfiles)) | $(call totarget,sign)
	@echo + ld $@
	$(V)$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 $^ -o $(call toobj,bootblock)
	@$(OBJDUMP) -S $(call objfile,bootblock) > $(call asmfile,bootblock)
	@$(OBJCOPY) -S -O binary $(call objfile,bootblock) $(call outfile,bootblock)
	@$(call totarget,sign) $(call outfile,bootblock) $(bootblock)

...

$(kernel): $(KOBJS)

...

$(UCOREIMG): $(kernel) $(bootblock)
	$(V)dd if=/dev/zero of=$@ count=10000
	$(V)dd if=$(bootblock) of=$@ conv=notrunc
	$(V)dd if=$(kernel) of=$@ seek=1 conv=notrunc
```
其中UCOREIMG值为`bin/ucore.img`、kernel为`bin/kernel`、bootblock为`bin/bootblock`

先编译、链接生成bin/kernel文件
```shell
+ cc kern/trap/trapentry.S
+ cc kern/trap/vectors.S
+ cc kern/mm/pmm.c
+ cc libs/printfmt.c
+ cc libs/string.c
+ ld bin/kernel
```

然后再编译、链接生成bin/bootblock
```shell
➜  lab1 git:(lab1) ✗ make bin/bootblock
+ cc boot/bootasm.S
+ cc boot/bootmain.c
+ cc tools/sign.c
+ ld bin/bootblock
'obj/bootblock.out' size: 492 bytes
build 512 bytes boot sector: 'bin/bootblock' success!
```

最后，通过三条命令，生成bin/ucore.img
```shell
➜  lab1 git:(lab1) ✗ make -n bin/ucore.img
dd if=/dev/zero of=bin/ucore.img count=10000
dd if=bin/bootblock of=bin/ucore.img conv=notrunc
dd if=bin/kernel of=bin/ucore.img seek=1 conv=notrun
```

## 参考
- [Makefile 入门教程](https://blog.csdn.net/K346K346/article/details/50222577)
- [makefile中常用函数](https://blog.csdn.net/yangxuan0261/article/details/52060582)
- [Makefile中.PHONY的作用](https://www.cnblogs.com/idorax/p/9306528.html)

### Makefile原理
主Makefile中include `tools/function.mk`，后者中定义了很多帮助函数

Makefile中一些变量的值：
- UCOREIMG为bin/ucore.img
- kernel为bin/kernel，依赖tools/kernel.ld

### .PHONY作用
Makefile中的核心语法是
```shell
target: prerequisites
	command
```
其中`target`可以理解为前项目需要编译生成的目标文件。

make执行某个target时会分析该target的依赖，如果依赖更新了，当前target也会重新生成，如果没有则当前target为最新的(up to date)，不会执行。

通过.PHONY声明target是**伪目标**，不是目录下真实存在的文件，即使有make也不认。
在效果上，.PHONY声明的target每次都会执行。
在含义上，表示该target是伪目标，make不会把其当做目标对待