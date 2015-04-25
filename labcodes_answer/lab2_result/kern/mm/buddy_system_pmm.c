#include <pmm.h>
#include <list.h>
#include <string.h>
#include <default_pmm.h>

#define LEFT_LEAF(index) ((index) * 2 + 1)
#define RIGHT_LEAF(index) ((index) * 2 + 2)
#define PARENT(index) ( ((index) + 1) / 2 - 1)

#define IS_POWER_OF_2(x) (!((x)&((x)-1)))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)
//int nr_free;
// 二叉树节点
struct buddy2 {
	//unsigned size;
	unsigned left;
	unsigned right;
	unsigned longest;
	bool free;
	struct Page* page;
};

struct buddy2 bu[1<<17];
// 空闲空间的起始地址
struct Page * treebase;

// total 是对size进行修正后的二叉树的size大小
unsigned total;

// 如果size不是2的幂次，进行修正
static unsigned fixsize(unsigned size) {
	size |= size >> 1;
	size |= size >> 2;
	size |= size >> 4;
	size |= size >> 8;
	size |= size >> 16;
	return size+1;
}

static void
Buddy_init(void) {
    //list_init(&free_list);
    nr_free = 0;
}

//递归建树 ，对节点进行初始化
void init_tree(int root, int l, int r, struct Page *p){
	//cprintf("root=%d,l=%d,r=%d\n",root,l,r);
	//bu[root].size = r-l+1;
	bu[root].left = l;
	bu[root].right = r;
	bu[root].longest = r-l+1;
	bu[root].page = p;
	bu[root].free=0;
	if (l==r) return;
	int mid=(l+r)>>1;
	init_tree(LEFT_LEAF(root),l,mid,p);
	init_tree(RIGHT_LEAF(root),mid+1,r,p+(r-l+1)/2);
	
}
// 对树进行修正，以为有一些空间是不能被分配的
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
		bu[index].free=1;
		return;
	}
	fixtree(LEFT_LEAF(index),n);
	fixtree(RIGHT_LEAF(index),n);
	bu[index].longest = MAX(bu[LEFT_LEAF(index)].longest,bu[RIGHT_LEAF(index)].longest);
}

// 传入size ，这个size不一定是2的幂次，进行修正以后建二叉树，再对页进行初始化
static void
Buddy_init_memmap(struct Page *base, size_t n) {
	cprintf("\n----------------------------init_memap total_free_page:%d\n",n);
    assert(n > 0);
	total = fixsize(n);
	treebase = base;
	cprintf("----------------------------tree size is :%d.\n",total);
	init_tree(0,0,total-1,base);
	fixtree(0,n);
	struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = 0;
        SetPageProperty(p);
        p->property = 0;
        set_page_ref(p, 0);
        
    }
	cprintf("----------------------------init end\n\n");
    nr_free += n;
    //first block
    base->property = n;
}

// 通过递归 找到size大小的空闲区间，返回地址； 被alloc函数调用
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
	bu[index].free=1;
	return bu[index].page;
	
	}

// 分配空间
static struct Page *
Buddy_alloc_pages(size_t n) {
	
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
	struct Page * start =  search(0,n);
	if(start == NULL) return NULL;
	int i;
	for(i = 0; i < n; i++){
		SetPageReserved(start+i);
	}
	nr_free -= n;
	//cprintf("----alloc pages:%d %x\n",n,start);
	//if (n>1)
	cprintf("----alloc pages:%d %x\n",n,start);
	return start;
    
}

// 通过递归，查找相应位置，释放空间  free_pages函数调用
void freetree(int index, int pos, int size){
	int l = bu[index].left;
	int r = bu[index].right;
	int longest = bu[index].longest;
	bool free =bu[index].free;
	if (free==1)
	{
		bu[index].longest=r-l+1;
		bu[index].free=0;
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

// 释放空间 
static void
Buddy_free_pages(struct Page *base, size_t n) {
	cprintf("----free pages:%d %x\n",n,base,nr_free);
    assert(n > 0);
    assert(PageReserved(base));
	int tmp = base - treebase;
	//cprintf("tmp:%d\n",tmp);
	freetree(0,tmp,n);
	set_page_ref(base, 0);
    nr_free += n;
    return ;
}

static size_t
Buddy_nr_free_pages(void) {
    return nr_free;
}

// 输出树的信息
static void showpage_tree(int index)
{
	int l = bu[index].left;
	int r = bu[index].right;
	int longest = bu[index].longest;
	bool free=bu[index].free;
	if (r-l+1==longest)
	{
		cprintf("[%d,%d] is free, longest =%d\n",l,r,longest);
		return;
	}
	if (free==1)
	{
		cprintf("[%d,%d] is reserved, longest =%d\n",l,r,r-l+1);
		return;
	}
	showpage_tree(LEFT_LEAF(index));
	showpage_tree(RIGHT_LEAF(index));
		
}
static void showpage()
{
	cprintf("\n------------------\n");
	showpage_tree(0);
	cprintf("------------------\n\n");
	
}
static void
Buddy_check(void) {
	showpage();
	struct Page *p0 = alloc_pages(5);
	struct Page *p1 = alloc_pages(120);
	struct Page *p2 = alloc_pages(100);
	showpage();
	free_pages(p1,120);
	free_pages(p2,100);
	showpage();
	struct Page *p3 = alloc_pages(5000);
	showpage();
	free_pages(p0,5);
    showpage();
	free_pages(p3,5000);
	showpage();
}

const struct pmm_manager Buddy_pmm_manager = {
    .name = "Buddy_pmm_manager",
    .init = Buddy_init,
    .init_memmap = Buddy_init_memmap,
	.showpage =showpage,
    .alloc_pages = Buddy_alloc_pages,
    .free_pages = Buddy_free_pages,
    .nr_free_pages = Buddy_nr_free_pages,
    .check = Buddy_check,
};

