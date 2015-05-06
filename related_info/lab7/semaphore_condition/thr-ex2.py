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
