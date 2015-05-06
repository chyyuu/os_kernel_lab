#coding=utf-8
import threading  
import random  
import time  
  
class SemaphoreThread(threading.Thread):  
    """classusing semaphore"""  
     
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
#Semaphore类的一个对象用计数器跟踪获取和释放信号机的线程数量。  
#create ten threads  
for i in range(1,11):  
   threads.append(SemaphoreThread("thread"+str(i),threadSemaphore))  
#创建一个列表，该列表由SemaphoreThread对象构成，start方法开始列表中的每个线程  
#start each thread  
for thread in threads: 
   thread.start()  
