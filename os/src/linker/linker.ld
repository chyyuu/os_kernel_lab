/* rCore Linker Script */

/* Linker Script 语法可以参见：http://www.scoberlin.de/content/media/http/informatik/gcc_docs/ld_3.html */

/* 目标架构 */
OUTPUT_ARCH(riscv)

/* 执行入口 */
ENTRY(_start)

/* 数据存放起始地址 */
BASE_ADDRESS = 0x80200000;

SECTIONS
{   
    /* . 表示当前地址（location counter） */
    . = BASE_ADDRESS;

    /* start 符号表示全部的开始位置 */
    start = .;

    /* .text 字段 */
    .text : {
        stext = .;
        /* 把 entry 函数放在最前面 */
        *(.text.entry)
        /* 要链接的文件的 .text 字段集中放在这里 */
        *(.text .text.*)
        etext = .;
    }

    /* .rodata 字段 */
    .rodata : {
        srodata = .;
        /* 要链接的文件的 .rodata 字段集中放在这里 */
        *(.rodata .rodata.*)
        erodata = .;
    }

    /* .data 字段 */
    .data : {
        sdata = .;
        /* 要链接的文件的 .data 字段集中放在这里 */
        *(.data .data.*)
        edata = .;
    }

    /* stack 字段 */
    .stack : {
        /* 把 bss.stack 字段所申请的空间放在这里作为启动时的栈空间 */
        *(.bss.stack)
    }

    /* .bss 字段 */
    .bss : {
        sbss = .;
        /* 要链接的文件的 .bss 字段集中放在这里 */
        *(.bss .bss.*)
        ebss = .;
    }

    /* 结束地址 */
    kernel_end = .;
}