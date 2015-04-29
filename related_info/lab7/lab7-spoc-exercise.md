# lab7 理解race condition
## x86模拟运行环境
x86.py是一个模拟执行基于汇编代码的多线程执行过程的模拟器。这里的汇编语法是基于很简单的x86汇编语法。
且没有包括OS的调度、context切换和中断处理过程。每条指令大小为一个byte。每个变量占4个byte
在硬件上模拟了4个通用寄存器：
```
%ax, %bx, %cx, %dx
```
一个程序计数器`pc`，一个堆栈寄存器`sp`，和一小部分指令：
```
mov immediate, register     #  immediate value --> register
mov memory, register        #  memory --> register
mov register, register      #  register --> register
mov register, memory        #  register -->  memory
mov immediate, memory       #  immediate value -->  memory

add immediate, register     # register  = register  + immediate
add register1, register2    # register2 = register2 + register1
sub immediate, register     # register  = register  - immediate
sub register1, register2    # register2 = register2 - register1

test immediate, register    # compare immediate and register (set condition codes)
test register, immediate    # compare register and immediate (set condition codes)
test register, register     # compare register and register  (set condition codes)

jne                         # jump if test'd values are not equal
je                          # jump if test'd values are equal
jlt                         # jump if test'd second is less than  first
jlte                        # jump if test'd second is less than or equal first
jgt                         # jump if test'd second is greater than first
jgte                        # jump if test'd second is greater than or equal first

xchg register, memory       # atomic exchange: 
                            #   put value of register into memory
                            #   return old contents of memory into reg
                            #   do both things atomically

nop                         # no op
halt						# stop
push memory or register     # push value in memory or from reg onto stack
                            # stack is defined by sp register
pop [register]              # pop value off stack (into optional register)
call label                  # call function at label
yield                       # switch to the next thread in the runqueue
```
注意: 
 - 'immediate' 格式是 $number
 - 'memory'    格式是 'number' 或 '(reg)' 或 'number(reg)' 或 'number(reg,reg)'
  - (%cx)       ->  在括号中的register cx 的值 形成 address
  - 2000        ->  2000 形成 address
  - 1000(%dx)   ->  1000 + dx的值 形成 address
  - 10(%ax,%bx) ->  10  + ax的值 + bx的值 形成 address
 - 'register' 格式是 %ax, %bx, %cx, %dx


下面是一个代码片段：
```
.main
mov 2000, %ax   # 取地址2000处的内存单元的内容，并赋值给ax 
add $1, %ax     # ax=ax+1
mov %ax, 2000   # 把ax的内容存储到地址2000处的内存单元中
halt
```
其含义如下
```
  2000        -> 2000      	形成地址 address
  (%cx)       -> cx的内容    	形成地址 address
  1000(%dx)   -> （1000+dx） 形成地址 address
  10(%ax,%bx) -> (10+ax+bx)	形成地址 address
  halt        -> 执行结束
```

循环执行的小例子片段
```
.main
.top
sub  $1,%dx
test $0,%dx     
jgte .top         
halt
```

x86.py模拟器运行参数
```
  -h, --help            show this help message and exit
  -s SEED, --seed=SEED  the random seed
  -t NUMTHREADS, --threads=NUMTHREADS
                        number of threads
  -p PROGFILE, --program=PROGFILE
                        source program (in .s)
  -i INTFREQ, --interrupt=INTFREQ
                        interrupt frequency
  -r, --randints        if interrupts are random
  -a ARGV, --argv=ARGV  comma-separated per-thread args (e.g., ax=1,ax=2 sets
                        thread 0 ax reg to 1 and thread 1 ax reg to 2);
                        specify multiple regs per thread via colon-separated
                        list (e.g., ax=1:bx=2,cx=3 sets thread 0 ax and bx and
                        just cx for thread 1)
  -L LOADADDR, --loadaddr=LOADADDR
                        address where to load code
  -m MEMSIZE, --memsize=MEMSIZE
                        size of address space (KB)
  -M MEMTRACE, --memtrace=MEMTRACE
                        comma-separated list of addrs to trace (e.g.,
                        20000,20001)
  -R REGTRACE, --regtrace=REGTRACE
                        comma-separated list of regs to trace (e.g.,
                        ax,bx,cx,dx)
  -C, --cctrace         should we trace condition codes
  -S, --printstats      print some extra stats
  -v, --verbose         print some extra info
  -c, --compute         compute answers for me

```

执行举例
```
$ ./x86.py -p simple-race.s -t 1 -M 2000 -R ax,bx

 2000      ax    bx          Thread 0
    ?       ?     ?
    ?       ?     ?   1000 mov 2000, %ax
    ?       ?     ?   1001 add $1, %ax
    ?       ?     ?   1002 mov %ax, 2000
    ?       ?     ?   1003 halt
```

如果加上参数 `-c`可得到具体执行结果
```
$ ./x86.py -p simple-race.s -t 1 -M 2000 -R ax,bx -c

 2000      ax    bx          Thread 0
    0       0     0
    0       0     0   1000 mov 2000, %ax
    0       1     0   1001 add $1, %ax
    1       1     0   1002 mov %ax, 2000
    1       1     0   1003 halt
```

另外一个执行的例子
```
$ ./x86.py -p loop.s -t 1 -a dx=3 -R dx -C -c

   dx   >= >  <= <  != ==        Thread 0
    3   0  0  0  0  0  0
    2   0  0  0  0  0  0  1000 sub  $1,%dx
    2   1  1  0  0  1  0  1001 test $0,%dx
    2   1  1  0  0  1  0  1002 jgte .top
    1   1  1  0  0  1  0  1000 sub  $1,%dx
    1   1  1  0  0  1  0  1001 test $0,%dx
    1   1  1  0  0  1  0  1002 jgte .top
    0   1  1  0  0  1  0  1000 sub  $1,%dx
    0   1  0  1  0  0  1  1001 test $0,%dx
    0   1  0  1  0  0  1  1002 jgte .top
    0   1  0  1  0  0  1  1003 halt
```

多线程存在race condition 的例子 looping-race-nolock.s 
```
.main
.top
# critical section
mov 2000, %ax       # get the value at the address
add $1, %ax         # increment it
mov %ax, 2000       # store it back

# see if we're still looping
sub  $1, %bx
test $0, %bx
jgt .top

halt
```

执行结果：
```
$ ./x86.py -p looping-race-nolock.s -t 2 -a bx=1 -M 2000 -c

 2000      bx          Thread 0                Thread 1
    0       1
    0       1   1000 mov 2000, %ax
    0       1   1001 add $1, %ax
    1       1   1002 mov %ax, 2000
    1       0   1003 sub  $1, %bx
    1       0   1004 test $0, %bx
    1       0   1005 jgt .top
    1       0   1006 halt
    1       1   ----- Halt;Switch -----  ----- Halt;Switch -----
    1       1                            1000 mov 2000, %ax
    1       1                            1001 add $1, %ax
    2       1                            1002 mov %ax, 2000
    2       0                            1003 sub  $1, %bx
    2       0                            1004 test $0, %bx
    2       0                            1005 jgt .top
    2       0                            1006 halt
```

多线程存在  race condition 的例子 looping-race-nolock.s 在引入中断后，会产生race condition.
```
$ ./x86.py -p looping-race-nolock.s -t 2 -a bx=1 -M 2000 -i 2

 2000          Thread 0                Thread 1
    ?
    ?   1000 mov 2000, %ax
    ?   1001 add $1, %ax
    ?   ------ Interrupt ------  ------ Interrupt ------
    ?                            1000 mov 2000, %ax
    ?                            1001 add $1, %ax
    ?   ------ Interrupt ------  ------ Interrupt ------
    ?   1002 mov %ax, 2000
    ?   1003 sub  $1, %bx
    ?   ------ Interrupt ------  ------ Interrupt ------
    ?                            1002 mov %ax, 2000
    ?                            1003 sub  $1, %bx
    ?   ------ Interrupt ------  ------ Interrupt ------
    ?   1004 test $0, %bx
    ?   1005 jgt .top
    ?   ------ Interrupt ------  ------ Interrupt ------
    ?                            1004 test $0, %bx
    ?                            1005 jgt .top
    ?   ------ Interrupt ------  ------ Interrupt ------
    ?   1006 halt
    ?   ----- Halt;Switch -----  ----- Halt;Switch -----
    ?                            1006 halt
```


