.code32
SYSWRITE = 4    # sys_write()系统调用号
.global mywrite
.text
mywrite:
 pushl %ebp
 movl %esp, %ebp
 pushl %ebx
 movl 8(%ebp),%ebx  # ebx ：文件描述符
 movl 12(%ebp),%ecx  # ecx ：缓冲区指针
 movl 16(%ebp),%edx  # edx ：显示字符数
 movl $SYSWRITE,%eax   # eax ：系统调用号
 int $0x80
 popl %ebx
 mov %ebp, %esp
 popl %ebp
 ret
