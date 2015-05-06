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
                time.sleep(2)  
          
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
          
    for c in range(0, 10):  
        c = Consumer()  
        c.start() 
