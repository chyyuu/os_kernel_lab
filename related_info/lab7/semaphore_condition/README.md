
From:

- http://www.laurentluce.com/posts/python-threads-synchronization-locks-rlocks-semaphores-conditions-events-and-queues/
- http://yoyzhou.github.io/blog/2013/02/28/python-threads-synchronization-locks/
- http://blog.chinaunix.net/uid-429659-id-3186991.html
- http://blog.csdn.net/yidangui/article/details/8707187
- http://blog.csdn.net/yidangui/article/details/8707205
- http://blog.csdn.net/yidangui/article/details/8707209
- http://blog.csdn.net/yidangui/article/details/8707197

## threads: Python threads synchronization: Locks, RLocks, Semaphores, Conditions, Events and Queues.

### threading简介
python是支持多线程的，并且是native的线程。主要是通过thread和threading这两个模块来实现的。

#### 实现模块
 - thread：多线程的底层支持模块，一般不建议使用；
 - threading：对thread进行了封装，将一些线程的操作对象化。

#### threading模块 

 - Timer与Thread类似，但要等待一段时间后才开始运行；
 - Lock 锁原语，这个我们可以对全局变量互斥时使用；
 - RLock 可重入锁，使单线程可以再次获得已经获得的锁；
 - Condition 条件变量，能让一个线程停下来，等待其他线程满足某个“条件”；
 - Event 通用的条件变量。多个线程可以等待某个事件发生，在事件发生后，所有的线程都被激活；
 - Semaphore为等待锁的线程提供一个类似“等候室”的结构；
 - BoundedSemaphore 与semaphore类似，但不允许超过初始值；
 - Queue：实现了多生产者（Producer）、多消费者（Consumer）的队列，支持锁原语，能够在多个线程之间提供很好的同步支持。


thread是比较底层的模块，threading是对thread做了一些包装的，可以更加方便的被使用。创建thread的方式有：
 - 第一种方式:创建一个threading.Thread()的实例对象，给它一个函数。在它的初始化函数（__init__）中将可调用对象作为参数传入
 - 第二种方式:创建一个threading.Thread的实例，传给它一个可调用类对象，类中使用__call__()函数调用函数
 - 第三种方式:是通过继承Thread类，重写它的run方法；

第一种和第三种常用。



第一种方式举例：

```
#coding=utf-8
import threading  
  
def thread_fun(num):  
    for n in range(0, int(num)):  
        print " I come from %s, num: %s" %( threading.currentThread().getName(), n)  
  
def main(thread_num):  
    thread_list = list();  
    # 先创建线程对象  
    for i in range(0, thread_num):  
        thread_name = "thread_%s" %i  
        thread_list.append(threading.Thread(target = thread_fun, name = thread_name, args = (20,)))  
      
    # 启动所有线程     
    for thread in thread_list:  
        thread.start()  
      
    # 主线程中等待所有子线程退出  
    for thread in thread_list:  
        thread.join()  
  
if __name__ == "__main__":  
    main(3)  
```

第三种方式举例1：
```
#!/usr/bin/env python
import threading
import time
count=1

class KissThread(threading.Thread):
        def run(self):
                global count
                print "Thread # %s:Pretending to do stuff" % count
                count+=1
                time.sleep(2)
                print "done with stuff"


for t in range(5):
        KissThread().start()
```
第三种方式举例2：
```
import threading  
  
class MyThread(threading.Thread):  
    def __init__(self):  
        threading.Thread.__init__(self)  
      
    def run(self):  
        print "I am %s" % (self.name)  
      
if __name__ == "__main__":  
    for i in range(0, 5):  
        my_thread = MyThread()  
        my_thread.start()          
```




### Thread类常用方法
#### getName(self) 
返回线程的名字
#### setName方法
可以指定每一个thread的name
```
def __init__(self):  
    threading.Thread.__init__(self)  
    self.setName("new" + self.name)  
```
#### isAlive(self) 
布尔标志，表示这个线程是否还在运行中
####  isDaemon(self) 
返回线程的daemon标志
####   run(self) 
定义线程的功能函数
####  start方法
启动线程
####  join方法
 join方法原型如下，这个方法是用来程序挂起，直到线程结束，如果给出timeout，则最多阻塞timeout秒
``` 
def join(self, timeout=None):  
```
#### setDaemon方法
当我们在程序运行中，执行一个主线程，如果主线程又创建一个子线程，主线程和子线程就分兵两路，当主线程完成想退出时，会检验子线程是否完成。如果子线程未完成，则主线程会等待子线程完成后再退出。但是有时候我们需要的是，只要主线程完成了，不管子线程是否完成，都要和主线程一起退出，这时就可以用setDaemon方法，并设置其参数为True。


### Queue提供的类
 - Queue队列
 - LifoQueue后入先出（LIFO）队列
 - PriorityQueue 优先队列

### 互斥锁
Python编程中，引入了对象互斥锁的概念，来保证共享数据操作的完整性。每个对象都对应于一个可称为" 互斥锁" 的标记，这个标记用来保证在任一时刻，只能有一个线程访问该对象。在Python中我们使用threading模块提供的Lock类。添加一个互斥锁变量mutex = threading.Lock()，然后在争夺资源的时候之前我们会先抢占这把锁mutex.acquire()，对资源使用完成之后我们在释放这把锁mutex.release()。

当一个线程调用Lock对象的acquire()方法获得锁时，这把锁就进入“locked”状态。因为每次只有一个线程可以获得锁，所以如果此时另一个线程试图获得这个锁，该线程就会变为同步阻塞状态。直到拥有锁的线程调用锁的release()方法释放锁之后，该锁进入“unlocked”状态。线程调度程序从处于同步阻塞状态的线程中选择一个来获得锁，并使得该线程进入运行（running）状态。

```
import threading  
import time  
   
counter = 0  
mutex = threading.Lock()  
   
class MyThread(threading.Thread):  
    def __init__(self):  
        threading.Thread.__init__(self)  
      
    def run(self):  
        global counter, mutex  
        time.sleep(1);  
        if mutex.acquire():  
            counter += 1  
            print "I am %s, set counter:%s" % (self.name, counter)  
            mutex.release()  
      
if __name__ == "__main__":  
    for i in range(0, 100):  
        my_thread = MyThread()  
        my_thread.start()   
```        

### Condition条件变量
 Python提供的Condition对象提供了对复杂线程同步问题的支持。Condition被称为条件变量，除了提供与Lock类似的acquire和release方法外，还提供了wait和notify方法。使用Condition的主要方式为：线程首先acquire一个条件变量，然后判断一些条件。如果条件不满足则wait；如果条件满足，进行一些处理改变条件后，通过notify方法通知其他线程，其他处于wait状态的线程接到通知后会重新判断条件。不断的重复这一过程，从而解决复杂的同步问题。
 
另外：Condition对象的构造函数可以接受一个Lock/RLock对象作为参数，如果没有指定，则Condition对象会在内部自行创建一个RLock；除了notify方法外，Condition对象还提供了notifyAll方法，可以通知waiting池中的所有线程尝试acquire内部锁。由于上述机制，处于waiting状态的线程只能通过notify方法唤醒，所以notifyAll的作用在于防止有线程永远处于沉默状态。

#### “生产者-消费者”模型
代码中主要实现了生产者和消费者线程，双方将会围绕products来产生同步问题，首先是2个生成者生产products ，而接下来的4个消费者将会消耗products.


实现举例：
```
#coding=utf-8
#!/usr/bin/env python
  
import threading  
import time  
   
condition = threading.Condition()  
products = 0  
   
class Producer(threading.Thread):  
    def __init__(self):  
        threading.Thread.__init__(self)  
          
    def run(self):  
        global condition, products  
        while True:  
            if condition.acquire():  
                if products < 10:  
                    products += 1;  
                    print "Producer(%s):deliver one, now products:%s" %(self.name, products)  
                    condition.notify()  
                else:  
                    print "Producer(%s):already 10, stop deliver, now products:%s" %(self.name, products)  
                    condition.wait();  
                condition.release()  
                time.sleep(1)  
          
class Consumer(threading.Thread):  
    def __init__(self):  
        threading.Thread.__init__(self)  
          
    def run(self):  
        global condition, products  
        while True:  
            if condition.acquire():  
                if products > 1:  
                    products -= 1  
                    print "Consumer(%s):consume one, now products:%s" %(self.name, products)  
                    condition.notify()  
                else:  
                    print "Consumer(%s):only 1, stop consume, products:%s" %(self.name, products)  
                    condition.wait();  
                condition.release()  
                time.sleep(2)  
                  
if __name__ == "__main__":  
    for p in range(0, 2):  
        p = Producer()  
        p.start()  
          
    for c in range(0, 4):  
        c = Consumer()  
        c.start() 
```
### 信号量semaphore
semaphore是一个变量，控制着对公共资源或者临界区的访问。信号量维护着一个计数器，指定可同时访问资源或者进入临界区的线程数。每次有一个线程获得信号量时，计数器-1。若计数器为0，其他线程就停止访问信号量，直到另一个线程释放信号量。

```
#coding=utf-8
import threading  
import random  
import time  
  
class SemaphoreThread(threading.Thread):  
    """class using semaphore"""  
     
    availableTables=['A','B','C','D','E']
     
    def __init__(self,threadName,semaphore):  
       """initialize thread"""  
         
       threading.Thread.__init__(self,name=threadName)  
       self.sleepTime=random.randrange(1,6)  
       #set the semaphore as a data attribute of the class  
       self.threadSemaphore=semaphore
    def run(self):  
       """Print message and release semaphore"""  
         
       #acquire the semaphore  
       self.threadSemaphore.acquire()  
       #remove a table from the list  
       table=SemaphoreThread.availableTables.pop()  
       print "%s entered;seated at table %s." %(self.getName(),table),  
       print SemaphoreThread.availableTables  
       time.sleep(self.sleepTime)  
       #free a table  
       print " %s exiting;freeing table %s." %(self.getName(),table),  
       SemaphoreThread.availableTables.append(table)  
       print SemaphoreThread.availableTables  
       #release the semaphore after execution finishes  
       self.threadSemaphore.release()  
         
threads=[] #list of threads  
#semaphore allows five threads to enter critical section  
threadSemaphore=threading.Semaphore(len(SemaphoreThread.availableTables))  
#创建一个threading.Semaphore对象，他最多允许5个线程访问临界区。  
#Semaphore类的一个对象用计数器跟踪获取和释放信号量的线程数量。  
#create ten threads  
for i in range(1,11):  
   threads.append(SemaphoreThread("thread"+str(i),threadSemaphore))  
#创建一个列表，该列表由SemaphoreThread对象构成，start方法开始列表中的每个线程  
#start each thread  
for thread in threads: 
   thread.start()   
```
SemaphoreThread类的每个对象代表饭馆里的一个客人。类属性availableTables跟踪饭馆中可用的桌子。
信号量有个内建的计数器，用于跟踪他的acquire和release方法调用的次数。内部计数器的初始值可作为参数传给Semaphore构造函数。默认值为1.计数器大于0，Semaphore的acquire方法就为线程获得信号量，并计数器自减。


### 死锁现象
所谓死锁： 是指两个或两个以上的进程在执行过程中，因争夺资源而造成的一种互相等待的现象，若无外力作用，它们都将无法推进下去。此时称系统处于死锁状态或系统产生了死锁，这些永远在互相等待的进程称为死锁进程。 由于资源占用是互斥的，当某个进程提出申请资源后，使得有关进程在无外力协助下，永远分配不到必需的资源而无法继续运行，这就产生了一种特殊现象死锁。
```
import threading  
   
counterA = 0  
counterB = 0  
   
mutexA = threading.Lock()  
mutexB = threading.Lock()  
   
class MyThread(threading.Thread):  
    def __init__(self):  
        threading.Thread.__init__(self)  
      
    def run(self):  
        self.fun1()  
        self.fun2()  
          
    def fun1(self):  
        global mutexA, mutexB  
        if mutexA.acquire():  
            print "I am %s , get res: %s" %(self.name, "ResA")  
              
            if mutexB.acquire():  
                print "I am %s , get res: %s" %(self.name, "ResB")  
                mutexB.release()  
             
        mutexA.release()   
          
    def fun2(self):  
        global mutexA, mutexB  
        if mutexB.acquire():  
            print "I am %s , get res: %s" %(self.name, "ResB")  
              
            if mutexA.acquire():  
                print "I am %s , get res: %s" %(self.name, "ResA")  
                mutexA.release()  
             
        mutexB.release()   
      
if __name__ == "__main__":  
    for i in range(0, 100):  
        my_thread = MyThread()  
        my_thread.start()  
```
