# linux系统中查看程序page fault（缺页异常）信息

## 介绍
Linux关于page fault的类型：
 1. A major fault occurs when disk access required. For example, start an app called Firefox. The Linux kernel will search in the physical memory and CPU cache. If data do not exist, the Linux issues a major page fault.
 2. A minor fault occurs due to page allocation.
 
 
## 查看方法

 1. 使用`ps`命令
 ```
 ps -eo min_flt,maj_flt,pid,%cpu,%mem,pagein,args  --sort=min_flt


 min_flt : Number of minor page faults.
 maj_flt : Number of major page faults.
 PAGEIN  : Page Fault Count   (表示页面从磁盘加载到内存的次数)
 
 ```
