void inline ex1(void){
        asm ("movl $0xffff, %eax\n");
}

void inline ex2(void){
        unsigned cr0;
        asm volatile ("movl %%cr0, %0\n" :"=r"(cr0));
        cr0 |= 0x80000000;
        asm volatile ("movl %0, %%cr0\n" ::"r"(cr0));
}

void inline ex3(void){
long __res, arg1 = 2, arg2 = 22, arg3 = 222, arg4 = 233;
__asm__ __volatile__("int $0x80"
   : "=a" (__res)
   : "0" (11),"b" (arg1),"c" (arg2),"d" (arg3),"S" (arg4));
 }
