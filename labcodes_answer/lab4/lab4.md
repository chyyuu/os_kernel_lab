# 实验四：内核线程管理

## 练习一

### 实现方法

* 将proc_struct的state初始化为PROC_UNINIT，pid设为-1(表示未分配)，cr3设为boot_cr3

### struct context context

context结构体代表了当前进程的上下文，其中储存了8个寄存器的内容，并且顺序和`switch_to`函数中的操作对应，帮助实现的进程的切换

### struct trapframe *tf

trapframe为中断帧，保存了进程在发生中断时的运行状态，从而能够实现发生中断时保存进程现场，再次运行时回复现场

## 练习二

* 用`alloc_proc`分配一个新进程，若失败则直接返回
* 用`setup_kstack`设置内核栈，若失败则释放进程空间，然后返回
* `copy_mm`根据传入的clone_flags决定复制或共享当前进程的数据
* `copy_thread`设置进程上下文
* 将进程加入hash_list和proc_list
* 唤醒进程
* 设置返回值为进程pid并返回

ucore能保证进程pid的唯一，`get_pid`函数会依次增加last_pid的值并在到达MAX_PID时回绕，而可用的pid总数为最大进程数的两倍，因此总可以分配出空闲的pid给进程

## 练习三

* 若当前的进程是能够响应中断的则暂时关闭当前进程的中断功能
* 将proc的栈顶位置载入esp寄存器中
* 将proc的页目录表地址载入cr3寄存器
* 调用switch_to函数，切换到下一个函数执行
* 返回后打开CPU中断功能

创建了idleproc和initproc两个内核线程

`local_intr_save(intr_flag)`和`local_intr_restore(intr_flag)`用于暂时关闭中断功能，防止切换进程的过程被打断，是一种简易的实现互斥锁的方法

## 总结

### 实现与参考答案的区别

`do_fork`中参考答案在取得进程pid部分加了互斥锁

### 知识点

* 内核线程管理
* 调度并执行内核线程initproc
