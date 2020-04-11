# 宏：将寄存器存到栈上
.macro SAVE reg, offset
    sd  \reg, \offset*8(sp)
.endm

# 宏：将寄存器从栈中取出
.macro LOAD reg, offset
    ld  \reg, \offset*8(sp)
.endm

# 宏：保存所有寄存器到 TrapFrame
.macro SAVE_ALL
    # 在栈上开辟 TrapFrame 所需的空间
    addi    sp, sp, -36*8
    # 保存通用寄存器，除了 x0（固定为 0）
    SAVE    x1, 1
    SAVE    x2, 2
    SAVE    x3, 3
    SAVE    x4, 4
    SAVE    x5, 5
    SAVE    x6, 6
    SAVE    x7, 7
    SAVE    x8, 8
    SAVE    x9, 9
    SAVE    x10, 10
    SAVE    x11, 11
    SAVE    x12, 12
    SAVE    x13, 13
    SAVE    x14, 14
    SAVE    x15, 15
    SAVE    x16, 16
    SAVE    x17, 17
    SAVE    x18, 18
    SAVE    x19, 19
    SAVE    x20, 20
    SAVE    x21, 21
    SAVE    x22, 22
    SAVE    x23, 23
    SAVE    x24, 24
    SAVE    x25, 25
    SAVE    x26, 26
    SAVE    x27, 27
    SAVE    x28, 28
    SAVE    x29, 29
    SAVE    x30, 30
    SAVE    x31, 31

    # 取出 CSR 并保存
    csrr    s1, sstatus
    csrr    s2, sepc
    csrr    s3, stval
    csrr    s4, scause
    SAVE    s1, 32
    SAVE    s2, 33
    SAVE    s3, 34
    SAVE    s4, 35
.endm

# 宏：恢复 TrapFrame 中所有寄存器
.macro LOAD_ALL
    # 恢复 CSR
    LOAD    s1, 32
    LOAD    s2, 33
    # 思考：为什么不恢复 scause 和 stval？如果不恢复，为什么之前要保存
    csrw    sstatus, s1
    csrw    sepc, s2

    # 恢复通用寄存器
    LOAD    x1, 1
    LOAD    x3, 3
    LOAD    x4, 4
    LOAD    x5, 5
    LOAD    x6, 6
    LOAD    x7, 7
    LOAD    x8, 8
    LOAD    x9, 9
    LOAD    x10, 10
    LOAD    x11, 11
    LOAD    x12, 12
    LOAD    x13, 13
    LOAD    x14, 14
    LOAD    x15, 15
    LOAD    x16, 16
    LOAD    x17, 17
    LOAD    x18, 18
    LOAD    x19, 19
    LOAD    x20, 20
    LOAD    x21, 21
    LOAD    x22, 22
    LOAD    x23, 23
    LOAD    x24, 24
    LOAD    x25, 25
    LOAD    x26, 26
    LOAD    x27, 27
    LOAD    x28, 28
    LOAD    x29, 29
    LOAD    x30, 30
    LOAD    x31, 31
    LOAD    x2, 2
.endm


    .section .text
    .globl __interrupt
__interrupt:
    SAVE_ALL
    # TrapFrame 作为参数传入中断处理函数
    mv a0, sp
    jal handle_interrupt

    .globl __restore_frame
__restore_frame:
    LOAD_ALL
    # 返回地址是原先存储在 TrapFrame 中的
    sret