challenge1:完善ucore lab smp实现，扩展ticket lock机制（参考linux的ticket lock实现），能够在真实机器上把lab8跑起来，并能看出出smp 调度和同步互斥的特点
===================================================
状态：可基于田博的ucore lab smp当前实现（完成大部分）
完成人:

challenge2:改进并简化一个简化的CPU模拟器（这个简化CPU的目的就是为了支持ucore OS的进一步简化），把ucore lab8移植到此简化CPU上。
===================================================
提示: 基于　https://com.github/chyyuu/swieros ，已经在ubuntu 14.04上实验过，参考00README.txt　很容易测试运行起来。
状态：已有一个简化的CPU模拟器ex，一个简化的C子集编译器4c，一个基于此C子集的简化的xv6，4c编译的xv6可以运行在ex上。ex,4c,xv6的源码都在2000行以内。
要求：改进简化CPU模拟器ex，使得它像一个稍微扩展一点的Y86，修改C子集编译器4c,支持改进的ex，把xv6改成lab1~lab8的code.体现lab1~lab8的特点。此项目比较有意思，有一定的综合性，给分也会偏多一些。
完成人：

challenge3:理解ucore lab，基于ucore lab源码，给ucore lab生成参考文档。
===================================================
状态：类似 http://pdos.csail.mit.edu/6.828/2011/xv6/xv6-rev6.pdf 和它自动生成方式
要求：添加对于ucore lab的函数和重要数据结构的说明（中文注释，基于doxygen的格式），能对函数进行分类（比如memory::pmm....），这样可以采用doxygen自动生成ucore lab参考文档。lab1～lab8的很多注释内容应该可以复用。
完成人：

challenge4: porting ucore labs 在Intel galieo gen2开发板上(板子可到FIT楼3-124找助教要，需要留下小组的个人信息)
===================================================
状态：Intel galieo gen2开发板有详细的软硬件文档和linux软件，且Intel galieo gen2开发板采用的是本质是intel pentium５的intel Quark SoC X1000处理器。系统采用的是grub bootloader.
要求：lab1~lab8可以在Intel galieo gen2开发板上跑起来。需要写出移植报告，说明移植的过程等。
完成人:


challenge4: porting ucore labs 1~8在x86的笔记本电脑上,可以通过u盘启动并在grub bootloader上选择执行lab1～lab8
===================================================
状态：lab1已经完成了，可以作为参考
要求：lab1~lab8可以在x86的笔记本电脑上跑起来。需要写出移植报告，说明移植的过程等。
完成人:

