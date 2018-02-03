# 实验五：用户进程管理

## 练习一

### 实现方法

* 将中断帧的保存的cs和ds、es、ss分别指向用户代码段和用户数据段
* 将esp指向用户栈的栈顶
* 将eip设置为ELF文件提供的程序入口地址
* 设置eflags中控制中断的位

用户态进程从创建到执行

* 调用KERNEL_EXECVE宏，通过kernel_execve函数发出系统调用
* 经过多次函数调用到达do_execve函数
* 进入load_icode读入程序的数据段和代码段
* 修改栈帧
* 逐步返回，最后iret，恢复栈帧后程序开始运行
* 首先进入initcode.S，将ebp设为0，esp减小(用于printstackframe)
* 调用umain
* umain中调用main()函数，开始执行程序

## 练习二

### Copy on Write

* 在do_fork时不进行内存复制，只将对应内存页的页目录项中的R/W Bit设为只读
* 一旦发生写操作，就会引发page fault
* 在中断处理程序中恢复内存页的R/W状态
* 进行程序代码段、数据段的复制
* 返回继续执行

## 练习三

### fork/exec/wait/exit

用户态的fork/exec/wait/exit函数会调用/usrlibs/syscall.h中的相应函数，然后由`static inline int syscall(int num, ...)`中的内联汇编发出中断，通过系统调用实现各个功能。

用户态进程的执行状态生命周期图如下：

```                                            
  alloc_proc                                 RUNNING
      |                                   +--<----<--+
      |                                   | proc_run |
      V                                   +-->---->--+ 
PROC_UNINIT --> proc_init/wakeup_proc --> PROC_RUNNABLE --> try_free_pages/do_wait/do_sleep --> PROC_SLEEPING --+
                                           ^      |                                                             |
                                           |      +--- do_exit --> PROC_ZOMBIE                                  |
                                           |                                                                    |
                                           +----------------------wakeup_proc-----------------------------------+
```

## 总结

### 实现与参考答案的区别

实现相同

### 知识点

* 用户进程管理
* 系统调用实现：系统调用通过中断实现
