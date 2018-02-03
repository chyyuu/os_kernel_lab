# 实验七：同步互斥

## 练习一

### 内核信号量的实现

#### P操作

实现在`__down(semaphore_t *sem, uint32_t wait_state)`中：

* 关闭中断
* 判断当前信号量的值是否大于0
    * 若>0，则可得到状态量，让value减1，打开中断返回
    * 若<=0，则无法获得信号量
        * 将当前进程加入等待队列
        * 打开中断
        * 运行调度器

#### V操作

实现在`__up(semaphore_t *sem, uint32_t wait_state)`中：

* 关闭中断
* 若等待队列中午进程，则将value加1并打开中断返回
* 若有进程等待，则唤醒队首进程
* 打开中断

### 用户态信号量

首先通过test_and_set_bit指令实现Mutex

```c
static inline bool
test_and_set_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btsl %2, %1; sbbl %0, %0" : "=r" (oldbit), "=m" (*(volatile long *)addr) : "Ir" (nr) : "memory");
    return oldbit != 0;
}

typedef volatile bool lock_t;

static inline void
lock(lock_t *lock) {
    while (!try_lock(lock)) {
        schedule();
    }
}

static inline void
unlock(lock_t *lock) {
    if (!test_and_clear_bit(0, lock)) {
        panic("Unlock failed.\n");
    }
}
```

然后用`lock(lock_t *lock)`和`unlock(lock_t *lock)`代替内核级信号量实现中的`local_intr_save(intr_flag)`和`local_intr_restore(intr_flag)`即可

用户态信号量和内核态信号量主要区别是在内核态中可以通过关闭中断来实现互斥访问，而用户态中必须自己实现互斥锁

## 练习二

### 内核级条件变量

内核级条件变量condvar是基于信号量实现的，其定义如下：

```c
typedef struct condvar {
    semaphore_t sem;    // the sem semaphore  is used to down the waiting proc, and the signaling proc should up the waiting proc
    int count;          // the number of waiters on condvar
    monitor_t * owner;  // the owner(monitor) of this condvar
} condvar_t;
```

* cond_wait用来让进程等待直到条件满足，若发现条件不满足，则进程挂起直到其他进程调用cond_signal且该进程被唤醒为止
* cond_signal用来通知条件已经满足，此时等待队列中的某个进程会被唤醒，占据monitor

### 用户态条件变量

之前已经实现了用户态的mutex和semaphore，将内核态的条件变量中对应的信号量换成用户态的信号量即可实现用户态条件变量

### 不用信号量机制完成条件变量

可以使用mutex完成条件变量，ucore中的条件变量即是用信号量实现的。

## 总结

### 实现与参考答案的区别

实现与答案基本相同

### 知识点

* 信号量
* 管程和条件变量
