/* Linker Script 语法可以参见：http://www.scoberlin.de/content/media/http/informatik/gcc_docs/ld_3.html */

/* 目标架构 */
OUTPUT_ARCH(riscv)

/* 执行入口 */
ENTRY(_start)

/* 数据存放起始地址 */
BASE_ADDRESS = 0x10000;

SECTIONS
{   
    /* .text 字段 */
    .text : ALIGN(4K) {
        *(.text)
    }

    /* .rodata 字段 */
    .rodata : ALIGN(4K) {
        *(.rodata)
    }

    /* .data 字段 */
    .data : ALIGN(4K) {
        *(.data)
    }

    /* .bss 字段 */
    .bss : ALIGN(4K) {
        *(.sbss .bss)
    }
}