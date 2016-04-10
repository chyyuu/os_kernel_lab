.section __TEXT,__text
.globl start
start:
mov $0x1, %eax
push $0x0
call _syscall
_syscall:
int $0x80
