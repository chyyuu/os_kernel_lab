#include <riscv.h>

.text
.globl _start
_start:
    # call user-program function
    LOAD a0, 0(sp)
    addi a1, sp, 8
    call umain
1:  j 1b
