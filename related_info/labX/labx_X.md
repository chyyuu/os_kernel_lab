challenge1:完善ucore lab smp实现，扩展ticket lock机制（参考linux的ticket lock实现），能够在真实机器上把lab8跑起来，并能看出出smp 调度和同步互斥的特点
状态：可基于田博的ucore lab smp当前实现（完成大部分）
完成人:

challenge2:改进并简化一个简化的CPU模拟器（这个简化CPU的目的就是为了支持ucore OS的进一步简化），把ucore lab8移植到此简化CPU上。
状态：已有一个简化的CPU模拟器ex，一个简化的C子集编译器4c，一个基于此C子集的简化的xv6，4c编译的xv6可以运行在ex上。ex,4c,xv6的源码都在2000行以内。
要求：改进简化CPU模拟器ex，使得它像一个稍微扩展一点的Y86，修改C子集编译器4c,支持改进的ex，把xv6改成lab1~lab8的code.体现lab1~lab8的特点。此项目比较有意思，有一定的综合性，给分也会偏多一些。
完成人：
