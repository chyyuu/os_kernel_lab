

##练习1##


###操作系统镜像文件ucore.img是如何一步一步生成的？###

使用`make -n`查看make调用的命令

    i386-jos-elf-gcc -Ikern/init/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Ikern/debug/ -Ikern/driver/ -Ikern/trap/ -Ikern/mm/ -c kern/init/init.c -o obj/kern/init/init.o
    echo + cc kern/libs/readline.c
    i386-jos-elf-gcc -Ikern/libs/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Ikern/debug/ -Ikern/driver/ -Ikern/trap/ -Ikern/mm/ -c kern/libs/readline.c -o obj/kern/libs/readline.o
    echo + cc kern/libs/stdio.c
    i386-jos-elf-gcc -Ikern/libs/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Ikern/debug/ -Ikern/driver/ -Ikern/trap/ -Ikern/mm/ -c kern/libs/stdio.c -o obj/kern/libs/stdio.o
    echo + cc kern/debug/kdebug.c
    i386-jos-elf-gcc -Ikern/debug/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Ikern/debug/ -Ikern/driver/ -Ikern/trap/ -Ikern/mm/ -c kern/debug/kdebug.c -o obj/kern/debug/kdebug.o
    echo + cc kern/debug/kmonitor.c
    i386-jos-elf-gcc -Ikern/debug/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Ikern/debug/ -Ikern/driver/ -Ikern/trap/ -Ikern/mm/ -c kern/debug/kmonitor.c -o obj/kern/debug/kmonitor.o
    echo + cc kern/debug/panic.c
    i386-jos-elf-gcc -Ikern/debug/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Ikern/debug/ -Ikern/driver/ -Ikern/trap/ -Ikern/mm/ -c kern/debug/panic.c -o obj/kern/debug/panic.o
    echo + cc kern/driver/clock.c
    i386-jos-elf-gcc -Ikern/driver/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Ikern/debug/ -Ikern/driver/ -Ikern/trap/ -Ikern/mm/ -c kern/driver/clock.c -o obj/kern/driver/clock.o
    echo + cc kern/driver/console.c
    i386-jos-elf-gcc -Ikern/driver/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Ikern/debug/ -Ikern/driver/ -Ikern/trap/ -Ikern/mm/ -c kern/driver/console.c -o obj/kern/driver/console.o
    echo + cc kern/driver/intr.c
    i386-jos-elf-gcc -Ikern/driver/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Ikern/debug/ -Ikern/driver/ -Ikern/trap/ -Ikern/mm/ -c kern/driver/intr.c -o obj/kern/driver/intr.o
    echo + cc kern/driver/picirq.c
    i386-jos-elf-gcc -Ikern/driver/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Ikern/debug/ -Ikern/driver/ -Ikern/trap/ -Ikern/mm/ -c kern/driver/picirq.c -o obj/kern/driver/picirq.o
    echo + cc kern/trap/trap.c
    i386-jos-elf-gcc -Ikern/trap/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Ikern/debug/ -Ikern/driver/ -Ikern/trap/ -Ikern/mm/ -c kern/trap/trap.c -o obj/kern/trap/trap.o
    echo + cc kern/trap/trapentry.S
    i386-jos-elf-gcc -Ikern/trap/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Ikern/debug/ -Ikern/driver/ -Ikern/trap/ -Ikern/mm/ -c kern/trap/trapentry.S -o obj/kern/trap/trapentry.o
    echo + cc kern/trap/vectors.S
    i386-jos-elf-gcc -Ikern/trap/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Ikern/debug/ -Ikern/driver/ -Ikern/trap/ -Ikern/mm/ -c kern/trap/vectors.S -o obj/kern/trap/vectors.o
    echo + cc kern/mm/pmm.c
    i386-jos-elf-gcc -Ikern/mm/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Ikern/debug/ -Ikern/driver/ -Ikern/trap/ -Ikern/mm/ -c kern/mm/pmm.c -o obj/kern/mm/pmm.o
    echo + cc libs/printfmt.c
    i386-jos-elf-gcc -Ilibs/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/  -c libs/printfmt.c -o obj/libs/printfmt.o
    echo + cc libs/string.c
    i386-jos-elf-gcc -Ilibs/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/  -c libs/string.c -o obj/libs/string.o
    mkdir -p bin
    echo + ld bin/kernel
    i386-jos-elf-ld -m    elf_i386 -nostdlib -T tools/kernel.ld -o bin/kernel  obj/kern/init/init.o obj/kern/libs/readline.o obj/kern/libs/stdio.o obj/kern/debug/kdebug.o obj/kern/debug/kmonitor.o obj/kern/debug/panic.o obj/kern/driver/clock.o obj/kern/driver/console.o obj/kern/driver/intr.o obj/kern/driver/picirq.o obj/kern/trap/trap.o obj/kern/trap/trapentry.o obj/kern/trap/vectors.o obj/kern/mm/pmm.o  obj/libs/printfmt.o obj/libs/string.o
    i386-jos-elf-objdump -S bin/kernel > obj/kernel.asm
    i386-jos-elf-objdump -t bin/kernel | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$/d' > obj/kernel.sym
    echo + cc boot/bootasm.S
    i386-jos-elf-gcc -Iboot/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Os -nostdinc -c boot/bootasm.S -o obj/boot/bootasm.o
    echo + cc boot/bootmain.c
    i386-jos-elf-gcc -Iboot/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -Ilibs/ -Os -nostdinc -c boot/bootmain.c -o obj/boot/bootmain.o
    echo + cc tools/sign.c

    cc -Itools/ -g -Wall -O2 -c tools/sign.c -o obj/sign/tools/sign.o
    gcc -g -Wall -O2 obj/sign/tools/sign.o -o bin/sign
    echo + ld bin/bootblock
    i386-jos-elf-ld -m    elf_i386 -nostdlib -N -e start -Ttext 0x7C00 obj/boot/bootasm.o obj/boot/bootmain.o -o obj/bootblock.o
    i386-jos-elf-objdump -S obj/bootblock.o > obj/bootblock.asm
    i386-jos-elf-objdump -t obj/bootblock.o | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$/d' > obj/bootblock.sym
    i386-jos-elf-objcopy -S -O binary obj/bootblock.o obj/bootblock.out
    bin/sign obj/bootblock.out bin/bootblock
    dd if=/dev/zero of=bin/ucore.img count=10000
    dd if=bin/bootblock of=bin/ucore.img conv=notrunc
    dd if=bin/kernel of=bin/ucore.img seek=1 conv=notrunc

可以看到，分成以下几个部分：

1. 使用elf-gcc编译内核，代码位于 kern 目录下，保存为 bin/kernel，格式是标准 i386-elf。

    编译时期关键的参数为：
    -nostdinc  不使用标准库
    -fno-stack-protector  不生成用于检测缓冲区溢出的代码

    链接时期关键的参数为：
    -T <scriptfile>  让连接器使用指定的脚本

2. 编译 bootasm.S 和 bootmain.c，保存为 bootblock，其中关键参数有
    -Ttext  指定代码段开始位置

3. 通过调用本地 gcc 编译辅助工具 sign，并使用sign将 bootblock 修改为合法的 bootblock

4. 使用 dd 工具，生成最终的ucore.img，其中包括10000个 block ，第一个 block 为刚刚生成 bootblock，从第二个开始为生成的ELF文件 kernel。


###一个被系统认为是符合规范的硬盘主引导扇区的特征是什么？###

可以看到sign.c文件中，

    buf[510] = 0x55;
    buf[511] = 0xAA;

既扇区的最后两个字节分别为 0x55 0xAA


##练习2##


###从CPU加电后执行的第一条指令开始，单步跟踪BIOS的执行###

删除 gdbinit 中的 continue，可以使用gdb单步调试。可以看到第一条指令是：

    ```asm
    0xfffffff0:  ljmp   $0xf000,$0xe05b
    ```
长跳转之后，执行

    0x000fe05b:  cmpl   $0x0,%cs:0x6c30
    0x000fe062:  jne    0xfd34d

    0x000fe066:  xor    %ax,%ax
    0x000fe068:  mov    %ax,%ss

对比 qemu 的 bios.bin 文件，可以看到第一条代码位于 bios.bin 文件的末尾位置。


###在初始化位置0x7c00设置实地址断点,测试断点正常###

删除 gdbinit 中的 continue，手动设置断点并运行。触发断点后

###从0x7c00开始跟踪代码运行,将单步跟踪反汇编得到的代码与bootasm.S和 bootblock.asm进行比较###

    (gdb) disassemble
    Dump of assembler code for function start:
    => 0x00007c00 <+0>:     cli
       0x00007c01 <+1>:     cld
       0x00007c02 <+2>:     xor    %eax,%eax
       0x00007c04 <+4>:     mov    %eax,%ds
       0x00007c06 <+6>:     mov    %eax,%es
       0x00007c08 <+8>:     mov    %eax,%ss

对比 bootasm.S

    # start address should be 0:7c00, in real mode, the beginning address of the running bootloader
    .globl start
    start:
    .code16                                             # Assemble for 16-bit mode
        cli                                             # Disable interrupts
        cld                                             # String operations increment

        # Set up the important data segment registers (DS, ES, SS).
        xorw %ax, %ax                                   # Segment number zero
        movw %ax, %ds                                   # -> Data Segment
        movw %ax, %es                                   # -> Extra Segment
        movw %ax, %ss                                   # -> Stack Segment 

##练习3##

###为何开启A20，以及如何开启A20###

A20是第21根寻址线，为了兼容性。

###如何初始化GDT表###

通过LGDT指令

###如何使能和进入保护模式###

将cr0寄存器的CR0_PE_ON位置为1（第二位）

##练习4##

###bootloader如何读取硬盘扇区的###

ucore 的 bootloader 使用的是LBA模式的PIO（Program IO）方式。具体实现在 bootmain.c 中，

    static void
    readsect(void *dst, uint32_t secno) {
        // wait for disk to be ready
        waitdisk();

        outb(0x1F2, 1);                         // count = 1
        outb(0x1F3, secno & 0xFF);
        outb(0x1F4, (secno >> 8) & 0xFF);
        outb(0x1F5, (secno >> 16) & 0xFF);
        outb(0x1F6, ((secno >> 24) & 0xF) | 0xE0);
        outb(0x1F7, 0x20);                      // cmd 0x20 - read sectors

        // wait for disk to be ready
        waitdisk();

        // read a sector
        insl(0x1F0, dst, SECTSIZE / 4);
    }

其中 IO 地址为硬编码，只能访问第一块IDE硬盘。
读取较多数据时，封装成了 readseg 函数。其中使用简单循环多次读取。


###bootloader是如何加载ELF格式的OS###

bootloader 读入一个 ELF header 。检查文件头是否为合法的ELF文件，
读取program header，按照其中地址加载到内存，并从中ELF header中提取出ELF文件的入口地址。

##练习5##

###解释最后一行各个数值的含义###

调用 kern_init 函数的是 bootmain.c 中的 bootmain 函数。
这个函数由 bootmain.S 调用，调用之前设置了ebp为0，之后使用call指令，压栈两个uint32，ebp为0x7bf8。
eip值对应的指令为call *%eax（即`((void (*)(void))(ELFHDR->e_entry & 0xFFFFFF))();`的下一条指令。
kern_init没有参数，因此args后面数值为栈上的局部变量。
最后的0x7df5即为call *%eax



##练习6##

###中断描述符表(也可简称为保护模式下的中断向量表)中一个表项占多少字节？###

在保护模式下，中断向量表中的表项由8个字节组成，

    struct gatedesc {
        unsigned gd_off_15_0 : 16;      // low 16 bits of offset in segment
        unsigned gd_ss : 16;            // segment selector
        unsigned gd_args : 5;           // # args, 0 for interrupt/trap gates
        unsigned gd_rsv1 : 3;           // reserved(should be zero I guess)
        unsigned gd_type : 4;           // type(STS_{TG,IG32,TG32})
        unsigned gd_s : 1;              // must be 0 (system)
        unsigned gd_dpl : 2;            // descriptor(meaning new) privilege level
        unsigned gd_p : 1;              // Present
        unsigned gd_off_31_16 : 16;     // high bits of offset in segment
    };

###其中哪几位代表中断处理代码的入口?###

由 `gd_ss gd_off_15_0 gd_off_31_16` 拼接成代码的入口





