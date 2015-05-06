#coding=utf-8
#!/usr/bin/env python
import subprocess
from threading import Thread
from Queue import Queue

num_thread=3  #定义线程的数量
queue=Queue() #创建队列实例
ips=['192.168.1.100','192.168.1.110','192.168.1.120','192.168.1.130','192.168.1.200']

def pinger(i,q):
        while True:
                ip=q.get() #获取Queue队列传过来的ip，队列使用队列实例queue.put(ip)传入ip，通过q.get() 获得
                print "Thread %s:Pinging %s" %(i,ip)
                ret=subprocess.call("ping -c 1 %s" % ip,shell=True,stdout=open('/dev/null','w'),stderr=subprocess.STDOUT)
                #调用子进程执行命令，获取退出状态。不能使用subprocess.Popen也可以 
                if ret==0:
                        print "%s:is alive" % ip
                else:
                        print "%s:did not respond" % ip
                q.task_done() #告诉queue.join()已完成队列中提取元组的工作

for i in range(num_thread):#各线程开始工作
        worker=Thread(target=pinger,args=(i,queue)) #创建一个threading.Thread()的实例，给它一个函数以及函数的参数
        worker.setDaemon(True)    #在start方法被调用之前如果没有进行设置，程序会不定期挂起。
        worker.start()     #开始线程的工作，没有设置程序会挂起，不会开始线程的工作，因为pinger程序是while True循环

for ip in ips:
        queue.put(ip)    #将IP放入队列中。函数中使用q.get(ip)获取

print "Main Thread Waiting"
queue.join()    #防止主线程在其他线程获得机会完成队列中任务之前从程序中退出。
print "Done"
