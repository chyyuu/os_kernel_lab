challenge1: 实现精简版用户进程管理与切换
===================================================
要求：
(step1) 去掉页表的管理，分配内存功能，只保留段机制，中断，内核线程切换，用户进程切换，print功能。看看代码规模会小到什么程度。

状态：未完成
完成人：

challenge2: 实现用户进程的Copy on Write机制
===================================================
状态：基本完成
完成了一种情况（没有swap机制）

output.cow是实现了COW机制的输出，
output.norm是正常lab5的输出，
这两份输出都添加了相应的注释，方便理解实现和验证的思路

https://github.com/chyyuu/ucore_lab/tree/lab5_X/labcodes_answer/lab5_result

完成人：
李天润 ltrthu@163.com
沈光耀 thusgy2012@gmail.com

challenge3: 实现用户线程，且内核无法“看到”用户线程（即需要在用户态完成线程切换和线程管理）
===================================================
状态：未完成
完成人：


challenge4: 分析ucore 内存申请与释放，发现潜在的内存泄露现象
===================================================
目前ucore lab5_answer中，存在潜在的内存泄露现象，请通过设计一个方法来解决这个问题。
```
Lab5内存泄露？
实现完Lab5要求后，
执行make run-forktest，输出
 assertion failed: nr_free_pages_store == nr_free_pages()
Welcome to the kernel debug monitor!!
发现当fork的进程数max_child超过12时，会出现内存泄露。。。
打印上面两个值，输出如下：
should remain:31861 actually remain:31860
有1页没有被回收
```
状态：未完成
完成人：
