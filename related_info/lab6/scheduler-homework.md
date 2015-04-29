# 理解调度算法
## 实现３种调度算法（SJF，FIFO，RR），可基于python, ruby, C, C++，LISP等）模拟实现，并给出测试。请参考scheduler-homework.py代码或独自实现。
最后统计采用不同调度算法的每个任务的相关时间和总体的平均时间：
　- turnaround time　周转时间
　- response time 响应时间
　- wait time　等待时间

### 对模拟环境的抽象
- 任务/进程，及其执行时间
  Job 0 (length = 1)
  Job 1 (length = 4)
  Job 2 (length = 7)

 - 何时切换？
 - 如何统计？
 
### 执行结果

采用FIFO调度算法

```
 ./scheduler-homework.py  -p FIFO
ARG policy FIFO
ARG jobs 3
ARG maxlen 10
ARG seed 0

Here is the job list, with the run time of each job: 
  Job 0 ( length = 9 )
  Job 1 ( length = 8 )
  Job 2 ( length = 5 )


** Solutions **

Execution trace:
  [ time   0 ] Run job 0 for 9.00 secs ( DONE at 9.00 )
  [ time   9 ] Run job 1 for 8.00 secs ( DONE at 17.00 )
  [ time  17 ] Run job 2 for 5.00 secs ( DONE at 22.00 )

Final statistics:
  Job   0 -- Response: 0.00  Turnaround 9.00  Wait 0.00
  Job   1 -- Response: 9.00  Turnaround 17.00  Wait 9.00
  Job   2 -- Response: 17.00  Turnaround 22.00  Wait 17.00

  Average -- Response: 8.67  Turnaround 16.00  Wait 8.67

```

采用SJF调度算法
```
 ./scheduler-homework.py  -p SJF
ARG policy SJF
ARG jobs 3
ARG maxlen 10
ARG seed 0

Here is the job list, with the run time of each job: 
  Job 0 ( length = 9 )
  Job 1 ( length = 8 )
  Job 2 ( length = 5 )


** Solutions **

Execution trace:
  [ time   0 ] Run job 2 for 5.00 secs ( DONE at 5.00 )
  [ time   5 ] Run job 1 for 8.00 secs ( DONE at 13.00 )
  [ time  13 ] Run job 0 for 9.00 secs ( DONE at 22.00 )

Final statistics:
  Job   2 -- Response: 0.00  Turnaround 5.00  Wait 0.00
  Job   1 -- Response: 5.00  Turnaround 13.00  Wait 5.00
  Job   0 -- Response: 13.00  Turnaround 22.00  Wait 13.00

  Average -- Response: 6.00  Turnaround 13.33  Wait 6.00
```

采用RR调度算法
```
 ./scheduler-homework.py  -p RR
ARG policy RR
ARG jobs 3
ARG maxlen 10
ARG seed 0

Here is the job list, with the run time of each job: 
  Job 0 ( length = 9 )
  Job 1 ( length = 8 )
  Job 2 ( length = 5 )


** Solutions **

Execution trace:
  [ time   0 ] Run job   0 for 1.00 secs
  [ time   1 ] Run job   1 for 1.00 secs
  [ time   2 ] Run job   2 for 1.00 secs
  [ time   3 ] Run job   0 for 1.00 secs
  [ time   4 ] Run job   1 for 1.00 secs
  [ time   5 ] Run job   2 for 1.00 secs
  [ time   6 ] Run job   0 for 1.00 secs
  [ time   7 ] Run job   1 for 1.00 secs
  [ time   8 ] Run job   2 for 1.00 secs
  [ time   9 ] Run job   0 for 1.00 secs
  [ time  10 ] Run job   1 for 1.00 secs
  [ time  11 ] Run job   2 for 1.00 secs
  [ time  12 ] Run job   0 for 1.00 secs
  [ time  13 ] Run job   1 for 1.00 secs
  [ time  14 ] Run job   2 for 1.00 secs ( DONE at 15.00 )
  [ time  15 ] Run job   0 for 1.00 secs
  [ time  16 ] Run job   1 for 1.00 secs
  [ time  17 ] Run job   0 for 1.00 secs
  [ time  18 ] Run job   1 for 1.00 secs
  [ time  19 ] Run job   0 for 1.00 secs
  [ time  20 ] Run job   1 for 1.00 secs ( DONE at 21.00 )
  [ time  21 ] Run job   0 for 1.00 secs ( DONE at 22.00 )

Final statistics:
  Job   0 -- Response: 0.00  Turnaround 22.00  Wait 13.00
  Job   1 -- Response: 1.00  Turnaround 21.00  Wait 13.00
  Job   2 -- Response: 2.00  Turnaround 15.00  Wait 10.00

  Average -- Response: 1.00  Turnaround 19.33  Wait 12.00

```
