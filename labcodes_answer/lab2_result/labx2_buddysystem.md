#lab2X  实现Buddy System
小组成员：  
黄杰 2012011272  
袁源 2012011294   
杜鹃 2012011354  

##设计思路
Buddy System算法，简单说就是每次把一个正内存块对半切分，一直切到需要的大小分配出去。回收的时候，如果跟它配对的块也是未被使用的，就合并成一个大的块。

之前学长实现的算法是维护多个不同大小的free_list(2,4,8,16...)，算法的缺点在于释放空间时由于查找能否合并的块比较耗时。从这个角度出发，我们采取二叉树这个数据结构，因为 1）buddy system算法的“对半切分”思想很切合二叉树的特点； 2）快速搜索合并。标准算法下，分配和释放的时间复杂度都是 O(log N) 。  

##算法实现

1. 二叉树节点

```
struct buddy2 {
	unsigned left;
	unsigned right;
	unsigned longest;
	struct Page* page;
};
```
其中，left和right表示一个节点表示的空间范围；longest表示此节点中的空间最多分配的大小；page表示此节点表示的空间范围的起始页地址。比如 根节点可能是（0，1023），其中（0，10）是被占用的页，则此节点的longest值为1024/2 = 512.  

2.  分配空间  
主要实现函数：  
```
struct Page * 
	search(int index,int size){
	int longest = bu[index].longest;
	
	if(size>longest) return NULL;
	if(bu[LEFT_LEAF(index)].longest >= size){
		struct Page * tmp = search(LEFT_LEAF(index),size);
		bu[index].longest = MAX(bu[LEFT_LEAF(index)].longest,bu[RIGHT_LEAF(index)].longest);
		return tmp;
	}
	if(bu[RIGHT_LEAF(index)].longest >= size){
		struct Page * tmp = search(RIGHT_LEAF(index),size);
		bu[index].longest = MAX(bu[LEFT_LEAF(index)].longest,bu[RIGHT_LEAF(index)].longest);
		return tmp;
	}
	bu[index].longest = 0;
	return bu[index].page;
	
	}
```

通过递归的方法，在二叉树中查找满足条件的节点，先左孩子再右孩子，并对父亲节点的longest进行修正：如果孩子节点不够，必须将此节点分配，则置为0，否则置为两个孩子longest的较大值。  

在`Buddy_alloc_pages`函数中调用方式：`struct Page * start =  search(0,n);`

3. 释放空间  
主要实现函数：  
```
void freetree(int index, int pos, int size){
	int l = bu[index].left;
	int r = bu[index].right;
	int longest = bu[index].longest;
	if (longest==0)
	{
		bu[index].longest=r-l+1;
		return;
	}
	int mid=(l+r)>>1;
	if (mid>=pos) freetree(LEFT_LEAF(index),pos,size);
		else
			freetree(RIGHT_LEAF(index),pos,size);
	int l1 = bu[LEFT_LEAF(index)].longest;
	int r1 = bu[RIGHT_LEAF(index)].longest;
	//cprintf("%d,%d,%d\n",l1,r1,r-l+1);
	if (l1+r1==r-l+1) bu[index].longest =r-l+1;
	else
		bu[index].longest = MAX(l1,r1);
}
```

通过递归的方法，查找被释放空间对应的节点（传入参数POS为被释放节点在数组中的位置）。合并的操作是：看左右孩子的longest是否相同，若相同则合并。  

4. 对树的修正  
因为buddy system 每次分配都是2的幂次大小，而分配时传入参数并不一定满足此条件（比如分配10大小的空间），则首先需要对size进行修正：  
```
static unsigned fixsize(unsigned size) {
	size |= size >> 1;
	size |= size >> 2;
	size |= size >> 4;
	size |= size >> 8;
	size |= size >> 16;
	return size+1;
}
```

因为建树也是2的幂次，但实际空闲空间不一定满足此条件，如是1000，则需要对树中的一些节点做些处理，将其longest置为0，表示此节点不能被分配：  
```
void fixtree(int index,int n)
{
	
	int l = bu[index].left;
	int r = bu[index].right;
	//cprintf("l:%d,r:%d,log:%d\n",l,r,bu[index].longest);
	int mid = (l+r)>>1;
	if (r < n)return ;
	if (l>=n)
	{
		bu[index].longest=0;
		return;
	}
	fixtree(LEFT_LEAF(index),n);
	fixtree(RIGHT_LEAF(index),n);
	bu[index].longest = MAX(bu[LEFT_LEAF(index)].longest,bu[RIGHT_LEAF(index)].longest);
}
```



##测试及结果   
//内容为分析
设计了
```
static void showpage_tree(int index)
{
	int l = bu[index].left;
	int r = bu[index].right;
	int longest = bu[index].longest;
	if (r-l+1==longest)
	{
		cprintf("[%d,%d] is free, longest =%d\n",l,r,longest);
		return;
	}
	if (longest==0)
	{
		cprintf("[%d,%d] is reserved, longest =%d\n",l,r,r-l+1);
		return;
	}
	showpage_tree(LEFT_LEAF(index));
	showpage_tree(RIGHT_LEAF(index));
		
}
```
函数作为整个内存使用情况的输出分析函数。  
输出格式为[x,y]给出区间，并给出区间是否被使用，与区间长度。

```
----------------------------init_memap total_free_page:31452//初始化，初始化空闲页面为31452个
----------------------------tree size is :32768.//建立一棵叶子节点数为32768的完全二叉树，同时对[31452,32767]的点置为已经被占用。
----------------------------init end
//以下为初始的内存使用的状态。
------------------
[0,16383] is free, longest =16384
[16384,24575] is free, longest =8192
[24576,28671] is free, longest =4096
[28672,30719] is free, longest =2048
[30720,31231] is free, longest =512
[31232,31359] is free, longest =128
[31360,31423] is free, longest =64
[31424,31439] is free, longest =16
[31440,31447] is free, longest =8
[31448,31451] is free, longest =4
[31452,31455] is reserved, longest =4
[31456,31487] is reserved, longest =32
[31488,31743] is reserved, longest =256
[31744,32767] is reserved, longest =1024
------------------

----alloc pages:5//分配大小为5的连续内存
-----alloc_result:c042c440
----alloc pages:120//分配大小为120的连续内存
-----alloc_result:c042d440
----alloc pages:100//分配大小为100的连续内存
-----alloc_result:c042e440

//以下为三次分配后的结果，可以看到[0,7],[128,255],[256,383]，已经分别被要求分配5,120,100的三次请求所占用。
------------------
[0,7] is reserved, longest =8
[8,15] is free, longest =8
[16,31] is free, longest =16
[32,63] is free, longest =32
[64,127] is free, longest =64
[128,255] is reserved, longest =128
[256,383] is reserved, longest =128
[384,511] is free, longest =128
[512,1023] is free, longest =512
[1024,2047] is free, longest =1024
[2048,4095] is free, longest =2048
[4096,8191] is free, longest =4096
[8192,16383] is free, longest =8192
[16384,24575] is free, longest =8192
[24576,28671] is free, longest =4096
[28672,30719] is free, longest =2048
[30720,31231] is free, longest =512
[31232,31359] is free, longest =128
[31360,31423] is free, longest =64
[31424,31439] is free, longest =16
[31440,31447] is free, longest =8
[31448,31451] is free, longest =4
[31452,31455] is reserved, longest =4
[31456,31487] is reserved, longest =32
[31488,31743] is reserved, longest =256
[31744,32767] is reserved, longest =1024
------------------
//释放120,100两块内存
----free pages:c042d440,120
----free pages:c042e440,100
//释放后的内存布局如下，[128,255]释放后依旧保持这个区间的形态，[256,383]释放后与大小同为128的[384,511]合并为[256,511]，而不是和大小为128的[128,255]合并。这个例子验证了所写的buddy system的合并规则与设计一致，是正确的。
------------------
[0,7] is reserved, longest =8
[8,15] is free, longest =8
[16,31] is free, longest =16
[32,63] is free, longest =32
[64,127] is free, longest =64
[128,255] is free, longest =128
[256,511] is free, longest =256
[512,1023] is free, longest =512
[1024,2047] is free, longest =1024
[2048,4095] is free, longest =2048
[4096,8191] is free, longest =4096
[8192,16383] is free, longest =8192
[16384,24575] is free, longest =8192
[24576,28671] is free, longest =4096
[28672,30719] is free, longest =2048
[30720,31231] is free, longest =512
[31232,31359] is free, longest =128
[31360,31423] is free, longest =64
[31424,31439] is free, longest =16
[31440,31447] is free, longest =8
[31448,31451] is free, longest =4
[31452,31455] is reserved, longest =4
[31456,31487] is reserved, longest =32
[31488,31743] is reserved, longest =256
[31744,32767] is reserved, longest =1024
------------------
//分配一个大小为5000的内存块
----alloc pages:5000
-----alloc_result:c046c440
//占用[8192,16383]大小为8192的内存块。
------------------
[0,7] is reserved, longest =8
[8,15] is free, longest =8
[16,31] is free, longest =16
[32,63] is free, longest =32
[64,127] is free, longest =64
[128,255] is free, longest =128
[256,511] is free, longest =256
[512,1023] is free, longest =512
[1024,2047] is free, longest =1024
[2048,4095] is free, longest =2048
[4096,8191] is free, longest =4096
[8192,16383] is reserved, longest =8192
[16384,24575] is free, longest =8192
[24576,28671] is free, longest =4096
[28672,30719] is free, longest =2048
[30720,31231] is free, longest =512
[31232,31359] is free, longest =128
[31360,31423] is free, longest =64
[31424,31439] is free, longest =16
[31440,31447] is free, longest =8
[31448,31451] is free, longest =4
[31452,31455] is reserved, longest =4
[31456,31487] is reserved, longest =32
[31488,31743] is reserved, longest =256
[31744,32767] is reserved, longest =1024
------------------

----free pages:c042c440,5
//释放最开始申请的，大小为5的块。前[0,8191]合并为一大块。
------------------
[0,8191] is free, longest =8192
[8192,16383] is reserved, longest =8192
[16384,24575] is free, longest =8192
[24576,28671] is free, longest =4096
[28672,30719] is free, longest =2048
[30720,31231] is free, longest =512
[31232,31359] is free, longest =128
[31360,31423] is free, longest =64
[31424,31439] is free, longest =16
[31440,31447] is free, longest =8
[31448,31451] is free, longest =4
[31452,31455] is reserved, longest =4
[31456,31487] is reserved, longest =32
[31488,31743] is reserved, longest =256
[31744,32767] is reserved, longest =1024
------------------

----free pages:c046c440,5000
//释放5000的内存块后，内存使用情况恢复到初始情况。
------------------
[0,16383] is free, longest =16384
[16384,24575] is free, longest =8192
[24576,28671] is free, longest =4096
[28672,30719] is free, longest =2048
[30720,31231] is free, longest =512
[31232,31359] is free, longest =128
[31360,31423] is free, longest =64
[31424,31439] is free, longest =16
[31440,31447] is free, longest =8
[31448,31451] is free, longest =4
[31452,31455] is reserved, longest =4
[31456,31487] is reserved, longest =32
[31488,31743] is reserved, longest =256
[31744,32767] is reserved, longest =1024
------------------

check_alloc_page() succeeded!
//经验证，buddy system实现正确。
```





##以上为1.0版本，2.0版本修正了其中存在的一个bug
bug原因1：  
在判断当前节点时候被占用的时候，条件为longest字段等于0,认为当某个节点可用长度为0的时候，表示这个节点被单个连续内存需求块所占用。存在这样一种情况，在多次运行alloc page 1后，叶节点的lonest为0,同时部分内部
节点的longest（因为这个longest取的是max左右孩子的longest）也为0,这个时候会认为这些内部节点是被分配给了同一个地方。在free的时候会错误的把其作为一个整体free掉。


解决方案：  
对每个节点增加一个bool free；0表示这个节点未被占用，1表示这个节点作为整体被占用。在alloct_page和free_page的时候维护free。在free_page的时候利用free这个值来判断该节点是否是作为整体被分配了的，
来判断是应该free还是继续向子节点递归。

> swap.c在lab3中才出现。下面的内容其实没用
> 还有一处修改的地方，在swap.c中，里面有部分对free_list的调用，这个结构是default_pmm_page才有的。在我们buddy-system实现中并没有使用，删去即可，不影响使用。
