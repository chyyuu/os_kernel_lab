.text
.globl _start
_start:
    # call user-program function
    call umain
1:  j 1b
