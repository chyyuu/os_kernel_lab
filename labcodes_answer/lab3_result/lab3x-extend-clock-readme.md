# lab3X 改进的时钟算法的实现

小组成员：  
黄杰 2012011272  
袁源 2012011294 
杜鹃 2012011354
###代码文件：swap_extended_clock.c

###算法说明：
改进的时钟算法的主要思想是：  
1. 为每个页设置两个标志位，一个是accessed位表示访问位，一个是dirty位表示被写位。  
2. 维护一个与物理页面数目相等的环形链表，发生访问时，如果要访问的页存在，则将accessed位置为1，如果访问的同时也进行了修改，则将dirty位变为1。  
3. 如果发生了缺页，则从指针的位置开始循环寻找，同时对accessed位和dirty位进行修改，修改的方式是：  
```
	accessed  dirty
	(1,1)- > (0,1)
	(1,0)- >（0，0）
	(0,1)- > (0,0)
	(0,0) 置换        
```
当找到（0，0）时置换此页，并将指针下移。

###设计实现说明：  
1. 对页的访问和修改信息可以在二级页表中的pte得到，同时在本算法中需要对标志位进行修改，也是对与之对应的页表项进行修改。  
两个标志位在原本的ucore代码里已经实现了，在mmu.h文件中：  
```
#define PTE_A           0x020                   // Accessed
#define PTE_D           0x040                   // Dirty
```
那么当缺页时需要对页的相应标志位进行修改，则可以方便进行修改，如：
```
(*pte) = (*pte) & (~PTE_A);

```   
2. 类比于fifo的实现，主要重写了`map_swappable`函数以及`swap_out_victim`函数。 维护的环形链表为`pra_list_head`，头指针为`clock_p`

3. 首先在init函数中，将头指针指向pra_list_head的起始地址  
4. 经过测验，当访问页时，相应的A位和D位都会被CPU修改不用操作系统进行专门修改，所以只要对发生缺页时的情况进行处理即可。

5. 在`_extended_clock_map_swappable`函数中 将换进的页加入链表：
```
list_add_before(clock_p, entry);
```

6. 在`_extended_clock_swap_out_victim`函数里，从clock_p指向的位置开始进行循环查找,查看每一页的A位和D位：

```
int accessed = (*pte)&(PTE_A)?1:0;
int dirty = (*pte)&(PTE_D)?1:0;
```

分为3种情况：
1）如果A为1，则将其变为0；
2）如果A为0，D为1 ，则D变为0；
3）如果都为0，则置换此页，且clock_p指针下移一位；  
具体代码如下：

```
		if (accessed) {
    		 cprintf("clock state: 0x%4x: A:%x, D:%x\n", page->pra_vaddr, accessed, dirty);
    		 (*pte) = (*pte) & (~PTE_A);
    		 cprintf("\tclock state: 0x%4x: A:%x, D:%x\n",page->pra_vaddr, (*pte)&(PTE_A)?1:0, (*pte)&(PTE_D)?1:0);
    	 }
    	 else if (!accessed && dirty) {
    		 cprintf("clock state: 0x%4x: A:%x, D:%x\n", page->pra_vaddr, accessed, dirty);
    		 (*pte) = (*pte) & (~PTE_D);
    		 cprintf("\tclock state: 0x%4x: A:%x, D:%x\n", page->pra_vaddr, (*pte)&(PTE_A)?1:0, (*pte)&(PTE_D)?1:0);
    	 } else if (!accessed && !dirty){
    	     struct Page *p = le2page(le, pra_page_link);
    	     list_del(le);
    	     clock_p = clock_p->next;
    	     assert(p !=NULL);
    	     *ptr_page = p;
			return 0;
		}
```

###特别说明  
我们在实现过程中发现了在ucore-lab3中的一个问题，在vmm.c的do_pgfault函数中
在调用完swap_map_swappable(mm, addr, page, 1);没有调用page->pra_vaddr=addr;将page的pra_vaddr的值置为正确的值，使得在使用时钟算法的时候出现了很多令人困惑的结果。这一问题其实再fifo实现中就出现了，但由于没有影响fifo的运行就没有被注意到。


###测试  
1. 测试函数在`_extended_clock_check_swap`函数中，具体为，


	unsigned char tmp;
	cprintf("write Virt Page e in extended_clock_check_swap\n");
    *(unsigned char *)0x5000 = 0x1e;
	
    cprintf("read Virt Page c in extended_clock_check_swap\n");
    tmp = *(unsigned char *)0x3000;

    cprintf("write Virt Page d in extended_clock_check_swap\n");
    *(unsigned char *)0x4000 = 0x0a;

    cprintf("read Virt Page a in extended_clock_check_swap\n");
    tmp = *(unsigned char *)0x1000;

    cprintf("write Virt Page b in extended_clock_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;

    cprintf("write Virt Page e in extended_clock_check_swap\n");
    *(unsigned char *)0x5000 = 0x1e;
	
	cprintf("write Virt Page c in extended_clock_check_swap\n");
    *(unsigned char *)0x3000 = 0x0e;
	
	cprintf("write Virt Page e in extended_clock_check_swap\n");
    *(unsigned char *)0x5000 = 0x2e;
	
	cprintf("read Virt Page c in extended_clock_check_swap\n");
    tmp = *(unsigned char *)0x3000;
	
	cprintf("write Virt Page e in extended_clock_check_swap\n");
    *(unsigned char *)0x5000 = 0x2e;
	cprintf("write Virt Page a in extended_clock_check_swap\n");
    *(unsigned char *)0x1000 = 0x1a;
	cprintf("write Virt Page a in extended_clock_check_swap\n");
    *(unsigned char *)0x1000 = 0x1a;

    cprintf("read Virt Page b in extended_clock_check_swap\n");
    tmp = *(unsigned char *)0x2000;

    cprintf("read Virt Page c in extended_clock_check_swap\n");
    tmp = *(unsigned char *)0x3000;

    cprintf("read Virt Page d in extended_clock_check_swap\n");
    tmp = *(unsigned char *)0x4000;

    cprintf("write Virt Page e in extended_clock_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;

    cprintf("read Virt Page a in extended_clock_check_swap\n");
    tmp = *(unsigned char *)0x1000;

    cprintf("write Virt Page b in extended_clock_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;

    cprintf("write Virt Page e in extended_clock_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;

总结一下就进行了：初始状态置入了abcd四页，然后进行了写e，读c，写d，读a，写b，写e，写c，写e，读c，写e，写a，写a，读b，读c，读d，写e，读a，写b，写e这些操作。下面来看一下执行时钟算法的流程。

2. 结果：
//内的是报告中分析的话

//初始状态：（a,b,c,d）在其中
//第一次写e，每次出现缺页会输出运行时钟算法的过程。

write Virt Page e in extended_clock_check_swap
page fault at 0x00005000: K/W [no page found].
//对第一个例子进行细致的解释
//首先给出运行前的表，其中0x1000,0x2000,0x3000,0x4000,分别对应abcd，A：表示acess位，D表示dirty位.
---start---
  clock state: 0x1000: A:1, D:1
  clock state: 0x2000: A:1, D:1
  clock state: 0x3000: A:1, D:1
  clock state: 0x4000: A:1, D:1
----end----
//以下格式表示环形链表中,扫过前AD两位状态，扫过后AD两位状态。
clock state: 0x1000: A:1, D:1//第一次扫过0x1000时，发现A=1，D=1
	clock state: 0x1000: A:0, D:1//那么将A置为0，D置为1
clock state: 0x2000: A:1, D:1
	clock state: 0x2000: A:0, D:1
clock state: 0x3000: A:1, D:1
	clock state: 0x3000: A:0, D:1
clock state: 0x4000: A:1, D:1
	clock state: 0x4000: A:0, D:1
clock state: 0x1000: A:0, D:1
	clock state: 0x1000: A:0, D:0
clock state: 0x2000: A:0, D:1
	clock state: 0x2000: A:0, D:0
clock state: 0x3000: A:0, D:1
	clock state: 0x3000: A:0, D:0
clock state: 0x4000: A:0, D:1
	clock state: 0x4000: A:0, D:0
//在扫到出现A=0，D=0的时候退出，在这次循环中，最终被T出的页式0x1000对应的页，T出后的结果如下，各个页的AD都已经被置为了0了。
--after--start---
->clock state: 0x2000: A:0, D:0
  clock state: 0x3000: A:0, D:0
  clock state: 0x4000: A:0, D:0
--after--end----

read Virt Page c in extended_clock_check_swap
//没有缺页，只会把C这页的A位置1
write Virt Page d in extended_clock_check_swap
//没有缺页，只会把D这页的A位置1，D位置1
read Virt Page a in extended_clock_check_swap
//读a产生缺页，进行时钟替换算法，如下描述：
page fault at 0x00001000: K/R [no page found].
//初始状态可以看到指针指向0x2000这页，这是上一次T出后的指针位置。其中0x3000这位的a是1，D是0，与上面读了c这页对应。0x4000,AD都为1与上面写了D对应。
---start---
  clock state: 0x5000: A:1, D:1
->clock state: 0x2000: A:0, D:0
  clock state: 0x3000: A:1, D:0
  clock state: 0x4000: A:1, D:1
----end----
//这次时钟算法不需要扫，因为一开始指向的0x2000就满足A=0D=0的条件，直接换出。换出后如下。
--after--start---
  clock state: 0x5000: A:1, D:1
->clock state: 0x3000: A:1, D:0
  clock state: 0x4000: A:1, D:1
--after--end----
write Virt Page b in extended_clock_check_swap
//下一步写B出现缺页
page fault at 0x00002000: K/W [no page found].
//初始状态：上一个操作为读A，所以新加入的0x1000的页的A=1，D=0，这是正确的。从指针指向的0x3000开始扫。
---start---
  clock state: 0x5000: A:1, D:1
  clock state: 0x1000: A:1, D:0
->clock state: 0x3000: A:1, D:0
  clock state: 0x4000: A:1, D:1
----end----
clock state: 0x3000: A:1, D:0//出现A=1，D=0的情况就将A置为0，指针下移
	clock state: 0x3000: A:0, D:0
clock state: 0x4000: A:1, D:1
	clock state: 0x4000: A:0, D:1
clock state: 0x5000: A:1, D:1
	clock state: 0x5000: A:0, D:1
clock state: 0x1000: A:1, D:0
	clock state: 0x1000: A:0, D:0
//T出了0x3000这个页，并在循环过程中置了0x5000,0x1000,0x4000的A位为0
--after--start---
  clock state: 0x5000: A:0, D:1
  clock state: 0x1000: A:0, D:0
->clock state: 0x4000: A:0, D:1
--after--end----
write Virt Page e in extended_clock_check_swap
//写e未缺页，会置AD都为1
write Virt Page c in extended_clock_check_swap
//写C缺页了,进行处理
page fault at 0x00003000: K/W [no page found].
//处理前状态，证实了上一指令写e未缺页时，将0x5000,A,D都置1.
---start---
  clock state: 0x5000: A:1, D:1
  clock state: 0x1000: A:0, D:0
  clock state: 0x2000: A:1, D:1
->clock state: 0x4000: A:0, D:1
----end----
clock state: 0x4000: A:0, D:1
	clock state: 0x4000: A:0, D:0
clock state: 0x5000: A:1, D:1
	clock state: 0x5000: A:0, D:1
//换出了0x1000这个页，得到如下
--after--start---
  clock state: 0x5000: A:0, D:1
->clock state: 0x2000: A:1, D:1
  clock state: 0x4000: A:0, D:0
--after--end----

//以下不再赘述，输出格式与上面相同，经过认真比对，与extend clock算法行为相同，通过例子测试了extend clock算法实现的正确性！
write Virt Page e in extended_clock_check_swap
read Virt Page c in extended_clock_check_swap
write Virt Page e in extended_clock_check_swap
write Virt Page a in extended_clock_check_swap
page fault at 0x00001000: K/W [no page found].

---start---
  clock state: 0x5000: A:1, D:1
  clock state: 0x3000: A:1, D:1
->clock state: 0x2000: A:1, D:1
  clock state: 0x4000: A:0, D:0
----end----
clock state: 0x2000: A:1, D:1
	clock state: 0x2000: A:0, D:1

--after--start---
  clock state: 0x5000: A:1, D:1
  clock state: 0x3000: A:1, D:1
  clock state: 0x2000: A:0, D:1
--after--end----
write Virt Page a in extended_clock_check_swap
read Virt Page b in extended_clock_check_swap
read Virt Page c in extended_clock_check_swap
read Virt Page d in extended_clock_check_swap
page fault at 0x00004000: K/R [no page found].

---start---
  clock state: 0x5000: A:1, D:1
  clock state: 0x3000: A:1, D:1
  clock state: 0x2000: A:0, D:1
  clock state: 0x1000: A:1, D:1
----end----
clock state: 0x5000: A:1, D:1
	clock state: 0x5000: A:0, D:1
clock state: 0x3000: A:1, D:1
	clock state: 0x3000: A:0, D:1
clock state: 0x2000: A:0, D:1
	clock state: 0x2000: A:0, D:0
clock state: 0x1000: A:1, D:1
	clock state: 0x1000: A:0, D:1
clock state: 0x5000: A:0, D:1
	clock state: 0x5000: A:0, D:0
clock state: 0x3000: A:0, D:1
	clock state: 0x3000: A:0, D:0

--after--start---
  clock state: 0x5000: A:0, D:0
  clock state: 0x3000: A:0, D:0
->clock state: 0x1000: A:0, D:1
--after--end----
write Virt Page e in extended_clock_check_swap
read Virt Page a in extended_clock_check_swap
write Virt Page b in extended_clock_check_swap
page fault at 0x00002000: K/W [no page found].

---start---
  clock state: 0x5000: A:1, D:1
  clock state: 0x3000: A:0, D:0
  clock state: 0x4000: A:1, D:0
->clock state: 0x1000: A:0, D:1
----end----
clock state: 0x1000: A:0, D:1
	clock state: 0x1000: A:0, D:0
clock state: 0x5000: A:1, D:1
	clock state: 0x5000: A:0, D:1

--after--start---
  clock state: 0x5000: A:0, D:1
->clock state: 0x4000: A:1, D:0
  clock state: 0x1000: A:0, D:0
--after--end----




