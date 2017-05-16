1. 增加一个内核线程。
    在proc_init函数中调用kernel_thread，产生init3线程

2. 把进程的生命周期和调度动态执行过程完整地展现出来：
	可以看到，首先在do_fork中创建线程，状态是PROC_UNINT。
	然后立刻将其设置为PROC_RUNNABLE，实际是有do_fork函数调用了wakeup_proc
	在线程主函数运行结束后，由kernel_thread_entry 调用了 do_exit 将线程状态设置为PROC_ZOMBIE
	然后回到idle线程，进入do_wait函数，将状态为PROC_ZOMBIE的线程从链表中移除。



use SLOB allocator
kmalloc_init() succeeded!
[SPOC]* now setting 1 to PROC_UNINIT in do_fork
[SPOC]* now setting 1 to PROC_RUNNABLE in wakeup_proc
[SPOC]* now setting 2 to PROC_UNINIT in do_fork
[SPOC]* now setting 2 to PROC_RUNNABLE in wakeup_proc
[SPOC]* now setting 3 to PROC_UNINIT in do_fork
[SPOC]* now setting 3 to PROC_RUNNABLE in wakeup_proc
proc_init:: Created kernel thread init_main--> pid: 1, name: init1
proc_init:: Created kernel thread init_main--> pid: 2, name: init2
proc_init:: Created kernel thread init_main--> pid: 3, name: init3
++ setup timer interrupts
[SPOC] schedule after proc_init. This will let idel_proc run
[SPOC] --will run init1:
 kernel_thread, pid = 1, name = init1
[SPOC] schedule by thread itself
[SPOC] --will run init2:
 kernel_thread, pid = 2, name = init2
[SPOC] schedule by thread itself
[SPOC] --will run init3:
 kernel_thread, pid = 3, name = init3
[SPOC] schedule by thread itself
[SPOC] --will run init1:
 kernel_thread, pid = 1, name = init1 , arg  init main1: Hello world!! 
[SPOC] schedule by thread itself
[SPOC] --will run init2:
 kernel_thread, pid = 2, name = init2 , arg  init main2: Hello world!! 
[SPOC] schedule by thread itself
[SPOC] --will run init3:
 kernel_thread, pid = 3, name = init3 , arg  init main2: Hello world!! 
[SPOC] schedule by thread itself
[SPOC] --will run init1:
[SPOC] schedule by thread itself
 kernel_thread, pid = 1, name = init1 ,  en.., Bye, Bye. :)
[SPOC] This thread is about to exit, will then execute do_exit
 do_exit: proc pid 1 will exit
 do_exit: proc  parent c02ff008
[SPOC]* now setting 1 to PROC_ZOMBIE in do_exit
[SPOC] schedule in do_exit
[SPOC] --will run init2:
[SPOC] schedule by thread itself
 kernel_thread, pid = 2, name = init2 ,  en.., Bye, Bye. :)
[SPOC] This thread is about to exit, will then execute do_exit
 do_exit: proc pid 2 will exit
 do_exit: proc  parent c02ff008
[SPOC]* now setting 2 to PROC_ZOMBIE in do_exit
[SPOC] schedule in do_exit
[SPOC] --will run init3:
[SPOC] schedule by thread itself
 kernel_thread, pid = 3, name = init3 ,  en.., Bye, Bye. :)
[SPOC] This thread is about to exit, will then execute do_exit
 do_exit: proc pid 3 will exit
 do_exit: proc  parent c02ff008
[SPOC]* now setting 3 to PROC_ZOMBIE in do_exit
[SPOC] schedule in do_exit
[SPOC] --will run idle:
do_wait: begin
do_wait: has kid find child  pid1
[SPOC] remove init1 from links
[SPOC] schedule after do_wait
[SPOC] --proccess remains in: idle
do_wait: begin
do_wait: has kid find child  pid2
[SPOC] remove init2 from links
[SPOC] schedule after do_wait
[SPOC] --proccess remains in: idle
do_wait: begin
do_wait: has kid find child  pid3
[SPOC] remove init3 from links
[SPOC] schedule after do_wait
[SPOC] --proccess remains in: idle
do_wait: begin
100 ticks