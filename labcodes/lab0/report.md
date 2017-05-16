#uCore的Windows编译环境的搭建#

ucore的编译环境要求以下几个部分：

1. GNU 环境，包括 make, sed, awk, dd。

2. 编译工具链，包括 i386-pc-elf（用于编译kernel image）和本机环境（用于编译辅助工具sign和mksfs）

3. git 版本控制工具

4. qemu 虚拟机

搭建的环境基于mingw（用于本地编译环境）和msys（包括基本GNU工具）

由于ucore的kernel image使用ELF文件格式，而在windows下默认编译为PE格式。因此需要交叉编译环境，
要求HOST=mingw，TARGET=i386-elf。因此需要首先编译一份i386-elf-gcc，具体方法如下：

1. 下载 binutils, cloog, gmp, isl, mpc, mpfr, gcc 源码

2. 编译 binutils，

```bash
	./configure --prefix=/i386-ucore-elf/ --target=i386-elf --enable-languages=c --disable-multilib
	make install 
```

3. 编译 gcc

```bash
	./configure --prefix=/i386-ucore-elf/ --target=i386-elf --disable-libquadmath --disable-libssp --enable-languages=c --disable-multilib
	make install 
```

将交叉编译环境和qemu加入PATH环境变量中

ucore的编译脚本中，检查了GCCPREFIX和QEMU两个环境变量。直接设置可以绕过自动检查，避免修改Makefile

```
	export GCCPREFIX=i386-elf-
	export QEMU=/qemu/qemu-system-i386
```

至此，可以实现简单的编译、调试。

*由于qemu的限制，windows环境下无法进行自动grade*