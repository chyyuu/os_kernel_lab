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
