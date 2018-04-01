### priv1.10 与 priv1.0x

被移植的rv32版本不是完全的priv1.10，某些指令和寄存器已经过时。

1. `sbadaddr`寄存器已过时，应使用`stval`寄存器。但直接使用`stval`有问题，需要用它的汇编码`0x143`代替。
2. 依据riscv-privileged-v1.10所述，`sfence.vm`指令已被移除了，应使用改进的`sfence.vma`指令。
3. `mbadaddr`寄存器己过时，应使用`mtval`寄存器。但直接使用`mtval不能识别`，需要用它的汇编码`0x343`代替。

### RV64与RV32的差异

#### 1. 寄存器
寄存器的名称和数量均一致，只是长度不同。RV64I是64位的，RV32I是32位的。
#### 2. 指令集
RV32I的指令RV64I均具备，且它们的编码是一致的，均为32位，不同点是RV32I指令操作的数据对象是32位的，而RV64I指令操作的数据对象是64位的。RV64I增设的指令均是为了操作32位数据而增加的。需要注意的是，伪指令rdcycle,rdtime,rdinstret分别读取的是相应寄存器的全部64位(cycle,time,instret计数器)，所以rdcycleh, rdtimeh, rdinstreth在RV64I里就不需要了，是非法的。
#### 3. 内存管理

RV32的内存管理规约是Sv32，RV64的内存管理规约是Sv39或Sv48。它们都是采用多级页表映射的方式实现从虚拟内存地址到物理内存地址的转换的。所不同的是Sv32是二级映射，Sv39是三级映射，Sv48是四级映射。Sv32的每个页表项占用4个字节，而Sv39和Sv48的每个页表项占用8个字节。Sv32是32位虚拟地址映射到34位物理地址，Sv39是39位的虚拟地址映射到56位的物理地址，Sv48是48位的虚拟地址映射到56位的物理地址。

#### 4. 其它

地址长度不同，elf格式不同，BBL是经过裁减的，RISCV的函数参数在寄存器而X86在内存。

#### 5. 总结

由于Ucore是使用C语言开发的，使用的接口也是SBI，所以移植的时候基本上可以不用考虑64位和32位指令集之间的差异。主要需要考虑的是寄存器里相应位的意义的改变，以及内存管理规约的不同。注：虽然不需要太关注指令集和寄存器的差异，但需要熟悉指令集和寄存器。

### lab1

#### 1. ucore的启动过程是怎样的？

其实知道了最终生成的**ucore.img**的结构，也就大致猜出来了启动过程。可以通过`make -n > make.txt`看看Makefile干了点什么，当然也可以直接看Makefile文件，但那比较费劲。可以发现，前面大部分都是在编译生成**kernel**，并通过`objdump`命令生成**kernel.asm**和**kernel.sym**，只有最后一行在riscv-pk目录以**kernel**做为payload编译生成了**bbl**，**bbl**就是最终的**ucore.img**。所以，可以发现kernel还是以前的kernel，而bootloader则是由riscv-pk提供的。

那么我们来看看riscv-pk究竟是什么？通过看它的README文件可见它包含了两个部分，一个Proxy Kernel和一个bbl。Proxy Kernel是AEE，是支持应用程序执行的。而bbl是SEE，是支持Proxy Kernel执行的。再看看configure文件，可以发现使用`--with-payload`参数是用**kernel**取代了**dummy_payload**。似乎没什么可以帮助理解的内容，那还是看看build目录下的Makefile说了点什么吧，依然是用`make -n > make.txt`命令。可以发现它把`bbl，dummy_payload，machine，util`四个文件夹下的C文件编译成了库，然后依赖这些库把bbl.c编译成了bbl。还可以发现bbl.lds文件指明了链接规则，bootloader的执行入口在**reset_vector** ，下一步到**init_first_hart**执行了一系列初始化操作，下一步到**boot_loader**函数里将程序入口指向了内核。至此，ucore的启动过程就大致清楚了。

#### 2. ucore lab1使用了riscv提供的哪些接口？

通过`grep -r asm`和`find -name "*.S"`两条命令的结果综合分析，可以看到接口主要由riscv.h和sbi.h两个文件提供，只有在clock.c、entry.S和trapentry.S里使用了汇编指令。clock.c是在get_cycles函数里用了rdtime指令来读取CSR寄存器stime的值。entry.S设置了栈，为进入C程序做准备。trapentry.S是load和store寄存器的值，用于中断的切换。另外，sbi.h里函数的地址是由sbi.S指定的，而sbi.S里为什么是那些地址，我想应该在riscv-pk里找答案了。

#### 3. lab1里ucore有些什么功能？

从kern_int函数来看，cons_init, pmm_init, pic_init都是空的，也就是console、物理内存和中断控制器均未初始化。从sbi来看，console和中断控制器应该是不需要初始化。而物理内存管理是lab2的内容，是真的没有初始化。cprintf函数最终是调用sbi_console_putchar实现其功能的，idt_init函数通过设置CSR寄存器stvec来实现设置中断服务例程的入口地址，clock_init函数控制时钟中断发生的频率，intr_enable函数使能中断。综上，ucore lab1主要是实现了cprintf函数和时钟中断。

#### 4. lab1移植过程。

64位下的地址和寄存器是64位的，所以不是int型而是long型的变量了。使用了sint_t和uint_t分别代表32位或64位模式下整型变量的长度，以支持不修改源代码而直接在32位或64位下的编译。
```c
#if __riscv_xlen == 64
  typedef int64_t sint_t;
  typedef uint64_t uint_t;
#else
  typedef int32_t sint_t;
  typedef uint32_t uint_t;
#endif

```
需要修改的文件夹有init.c，sbi.h， printfmt.c， defs.h。
另外，为了使中断能正常产生，还需要在init.c文件和trap.c文件内适当的地方放一条不输出任何内容的cprintf语句，这很奇怪但我还不知道是什么原因。

### lab2

#### 1. ucore lab2使用了riscv提供的哪些接口？

在lab1的基础上，lab2还在pmm.h和pmm.c里使用了`sfence.vm`指令，在atomic.h里使用了amo指令。

#### 2. lab2里ucore有些什么功能？

增加了物理内存管理的功能，即`pmm_init()`函数。pmm_init实现了两个功能，一是虚拟地址与物理地址的映射，二是把空闲内存组织成一个链表进行管理。

#### 3. lab2的移植过程
1. 需要以lab1的更改为基础。
2. 将使用了sfence.vm指令的地方都修改为sfence.vma指令。
3. 修改mmu.h。mmu.h文件实现了把虚拟地址的各个部分拆分开，把虚拟地址的各个部分再组装成一个虚拟地址，把页目录的某条记录转化成物理地址，以及对虚拟地址各部分的相关常数的定义。都要依据64位下的内存管理规约Sv39的要求进行修改。
4. 修改pmm.c。核心在于对get_pte函数的修改，get_pte函数的作用是利用页目录来找到虚拟地址la所在页表的地址。对于 Sv32来说只有一级页目录和一级页表，而Sv39有二级页目录和一级页表，把对二级页目录的操作抽象成一级页录的操作可以尽量复用代码，减小移植的工作量。
5. satp寄存器由32位变为了64位，相应位的意义也都不同了，需要进行相应的修改。
6. 需要注意的是，与lab1一样，lab2也需要在trap()函数内加一条cprintf语句才可以使中断正常运行。看起来似乎cprintf函数内存在一个隐藏的bug。

### lab3

#### 1. lab3里ucore有些什么功能？

增加了虚拟内存管理。do_pgfault函数是虚拟内存管理实现的关键。

#### 2. lab3的移植过程

1. 需要以lab2的更改为基础。
2. 虚拟内存和底层硬件关系不大，移植较简单。需要注意的是由于Sv39是三级页表映射，所以映射如果要建立的话会比Sv32多占用一个内存页，当运行check函数的时候需要注意这一点。

### lab4

#### 1. lab4有些什么功能？

lab4多了proc_init()和cpu_idle()两个函数，分别实现的是初始化进程控制块和实现进程调度的功能。

#### 2. lab4的移植过程。

1. lab4需要以lab3的移植为基础。再次回顾一下，Makefile修改工具链为64位，kernel.ld修改装载地址为0x80200000，defs.h创建新的数据类型，mmu.h修改为支持Sv39，pmm.c修改为支持三级页表、sfence.vma指令和64位地址，pmm.h修改为支持64位地址，memlayout.h修改KERNBASE和struct Page，修改vmm.c的nr_free_pages_store以适应三级页表。
2. 内核线程看来与硬件无关，无须更多的更改即可运行。

### lab5

#### 1. lab5有些什么功能？

#### 2. lab5移植过程。

1. lab5需要以lab3的移植为基础。
2. 需要在trap函数里加一条printf语句，否则无法触发中断。
3. 会触发CAUSE_FETCH_PAGE_FAULT异常，不知道原因何在。
4. syscall.c的参数要改为64位的。
5. kernel_execve函数实际上实现的是x86里int指令的功能，它有问题，不能正确地进行系统调用。
6. riscv.h的lcr3函数是针对Sv32的，需要改为Sv39。
7. elf.h修改为64位的格式。
8. amo指令操作32位的数据有可能会产生地址未对齐异常，在lab5需要把`bool`定义为`long long`类型。

### lab6

#### 1. lab6有些什么功能？

#### 2. lab6的移植过程。

1. lab6需要以lab5的移植为基础。

### lab7

#### 1. la7有些什么功能？

#### 2. lab7的移植过程。

1. 以lab6的移植为基础。
2. proc.c的put_kstack函数。
3. static_assert函数未实现。

###  lab8

#### 1. lab8有些什么功能？

#### 2. lab8的移植过程。

1. 以lab3的移植为基础。
2. proc.c的put_kstack函数。
3. static_assert函数未实现。
4. 整个文件系统中都要注意虚拟地址变为了64位。syscall.c, syscall.h, 
5. elf.h修改为64位格式。

### bug与修正

#### 1. 中断切换需要添加printf函数

- 问题描述：有的时候不能进入trap函数，需要在trap函数里加一条printf语句才能正常执行。
- 解决方案：在trapentry.S文件里加一条`.align 2`指令使所有的命令4字节对齐。
- 原因分析：riscv指令需要4字节对齐才能正常访问。当所有文件链接到一块的时候，由于汇编指令的存在使C语言里的指令没有4字节对齐。

### 参考资料

1. [sifive all aboard系列](https://www.sifive.com/blog/)