# 操作系统启动时所需的指令以及字段
#
# 我们在 linker.ld 中将程序入口设置为了 _start，因此在这里我们将填充这个标签
# 它将会执行一些必要操作，然后跳转至我们用 rust 编写的入口函数
#
# 关于 RISC-V 下的汇编语言，可以参考 https://rv8.io/asm.html
# %hi 表示取 [12,32) 位，%lo 表示取 [0,12) 位

    .section .text.entry
    .globl _start
# 目前 _start 的功能：将预留的栈空间写入 $sp，然后跳转至 rust_main
_start:
    # 计算 boot_page_table 的物理页号
    lui t0, %hi(boot_page_table)
    li t1, 0xffffffff00000000
    sub t0, t0, t1
    srli t0, t0, 12
    # 8 << 60 是 satp 中使用 Sv39 模式的记号
    li t1, (8 << 60)
    or t0, t0, t1
    # 写入 satp 并更新 TLB
    csrw satp, t0
    sfence.vma

    # 加载栈地址
    lui sp, %hi(bootstacktop)
    addi sp, sp, %lo(bootstacktop)
    # 跳转至 rust_main
    lui t0, %hi(rust_main)
    addi t0, t0, %lo(rust_main)
    jr t0

    # 回忆：bss 段是 ELF 文件中只记录长度，而全部初始化为 0 的一段内存空间
    # 这里声明字段 .bss.stack 作为操作系统启动时的栈
    .section .bss.stack
    .global bootstack
bootstack:
    .space 4096 * 4
    .global bootstacktop
bootstacktop:
    # 栈结尾

    # 初始内核映射所用的页表
    .section .data
    .align 12
boot_page_table:
    # 0x8000_0000 -> 0x8000_0000
    # 0xffff_ffff_8000_0000 -> 0x8000_0000
    .quad 0
    .quad (0x80000 << 10) | 0xcf
    .zero 508 * 8
    .quad (0x80000 << 10) | 0xcf
    .quad 0