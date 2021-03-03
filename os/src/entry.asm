    .section .text.entry
    .globl _start
_start:
    la sp, boot_stack_top
    call rust_main

     .section .bss.stack
    .global current
current:
    .space 4096

    .global task1
task1:
    .space 4096

    .global task2
task2:
    .space 4096

    .globl boot_stack
boot_stack:
    .space 4096 * 8
    .globl boot_stack_top
boot_stack_top:
    .globl t1_stack
t1_stack:
    .space 4096
    .globl boot_stack_top
t1_stack_top:
    .globl t2_stack
t2_stack:
    .space 4096
    .globl boot_stack_top
t2_stack_top: