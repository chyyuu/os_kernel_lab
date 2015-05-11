#!/usr/bin/env python
# -*- encoding: utf8 -*-
import os, sys
print "I'm going to fork now - the child will write something to a pipe, and the parent will read it back"
r, w = os.pipe()           # r,w是文件描述符, 不是文件对象
pid = os.fork()
if pid:
    # 父进程
    os.close(w)           # 关闭一个文件描述符
    r = os.fdopen(r)      # 将r转化为文件对象
    print "parent: reading"
    txt = r.read()
    os.waitpid(pid, 0)   # 确保子进程被撤销
else:
    # 子进程             
    os.close(r)
    w = os.fdopen(w, 'w')
    print "child: writing"
    w.write("here's some text from the child")
    w.close()
    print "child: closing"
    sys.exit(0)
print "parent: got it; text =", txt
