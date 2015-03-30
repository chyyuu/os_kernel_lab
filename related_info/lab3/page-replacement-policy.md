# 理解页置换算法
## 选择四种替换算法（0：LRU置换算法，1:改进的clock 页置换算法，2：工作集页置换算法，3：缺页率置换算法）中的一种来设计一个应用程序（可基于python, ruby, C, C++，LISP等）模拟实现，并给出测试。请参考page-replacement-policy.py 代码或独自实现。

###page-replacement-policy.py 代码

#### 对模拟环境的抽象

虚拟页访问序列：addresses=1,2,3,4,0,5....    这里面的最大值代表最大页号
页替换算法：policy=FIFO, LRU, OPT, CLOCK
CLOCK算法用的bit位数：clockbits=1
物理页帧大小：cachesize
实际保持的也访问序列：addrList [1,2,3,4,0,5,...]
物理页帧内容：memory [] 初始为空
当前占用的页帧数量：count  初始位0

#### 执行过程描述


```
for nStr in addrList:
       # for clock need to track the ref by reference bits
 
    	try:
			idx = memory.index(n)
			hits = hits + 1
			if policy == 'LRU' :
			    ....
		except:
	        idx = -1   #missing
            miss = miss + 1	
         
        if  idx=-1 and ...:  #missing and need replacement
         	#if phy page frames are full
         	     # for FIFO , LRU
              	 # replace victim item from memory  by " victim = memory.pop(0)" 
               
                 # for CLOCK
                 # find one page for the beginning of scan
                 # check ref[page] and update ref[page] 	 
                 # find a victim which ref[page]=0 by  memory.remove(page)
        else:
            # miss, but no replacement needed (phy page frame not full)
            # now add to memory         
            
        #update ref for clock replacement
```       
