# lab4_X 实现精简版内核线程管理与切换

删除页表管理、内存管理、中断

线程管理中，用到的内存管理相关的函数有 kmalloc, alloc_page 两个函数。用来分配线程管理结构 proc_struct 和线程堆栈。

本着最简单的实现，这里使用预先定义的两个数组分别存储。

struct proc_struct mem_struct[10] ;
char mem_stack[10][KSTACKSIZE] ;

目前没有实现释放功能，创建过超过10个线程之后就会出错。

替换掉 kmalloc, alloc_page 后，删除 mm 目录下的物理内存相关和页表相关代码即可。

由于之前用到的唯一中断是 page fault ，直接删除中断管理代码即可。

但是在 kdebug 中，也使用了trap的某些代码（用于显示调试信息），所以trap目录目前不能删除

【提示】其实可以进一步删除kdebug相关的无关内容，达到进一步精简的目的
