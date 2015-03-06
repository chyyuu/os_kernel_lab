#include <stdio.h>
#include <stdlib.h>
#include "list.h"

struct entry {

    list_entry_t node;
    int num;
};

int main() {
    struct entry head;
    list_entry_t* p = &head.node;
    list_init(p);
    head.num = 0;
    int i;
    for (i = 1; i != 10; i ++) {
        struct entry * e = (struct entry *)malloc(sizeof(struct entry));
        e->num = i;
        list_add(p, &(e->node));
        p = list_next(p);
    }
    //reverse list all node
    while ((p = list_prev(p)) != &head.node)
        printf("%d\n", ((struct entry *)p)->num);
    return 0;
}

// other examples

// ex1
#if 0
include "list.h";

void main() { 
	node_t node1; 
	node1.data = 1; 
	list_entry_t *n1 = &nodes1.node_link; 
	node_t node2; 
	node2.data = 2; 
	list_init(n1); 
	list_add_after(n1, &nodes2.node_link); 
    printf("\n"); 
}
#endif

//ex2
#if 0
#include "list.h"
#include "defs.h"
#include <stdio.h>

struct page {
    int test;
    list_entry_t page_link;
};

#define le2page(le, member)  to_struct((le), struct page, member)

#define to_struct(ptr, type, member)                               \
((type *)((char *)(ptr) - offsetof(type, member)))

#define offsetof(type, member)                                      \
        ((size_t)(&((type *)0)->member))


typedef struct {
    list_entry_t free_list;
    unsigned int nr_free;
}free_area_t;

int main(){
             
    free_area_t free_area;
    struct page pg;
    free_area.free_list.next = &pg.page_link;
        
    pg.test = 1;
    pg.page_link.next = &free_area.free_list;
    list_entry_t* le = &free_area.free_list;
    while ( (le = list_next(le)) != &free_area.free_list ) {
        struct page* p = le2page(le, page_link);
        printf ( "%d\n", p->test );
    }
    return 0;
}
#endif

//ex3
#if 0
#include <stdio.h>
#include "list.h"


int main(int argc, const char * argv[])
{
    list_entry_t HS0,HS1,HS2,HS3;

    list_init(&HS0);
    printf("%d %d %d\n",HS0.prev, HS0.next, &HS0);

    HS0.prev = NULL;
    HS0.next = &HS1;
    HS1.prev = &HS0;
    HS1.next = &HS2;
    HS2.prev = &HS1;
    HS2.next = NULL;

    list_add(&HS1, &HS3);

    printf("%d %d %d\n",HS0.prev, HS0.next, &HS0);
    printf("%d %d %d\n",HS1.prev, HS1.next, &HS1);
    printf("%d %d %d\n",HS3.prev, HS3.next, &HS3);
    printf("%d %d %d\n",HS2.prev, HS2.next, &HS2);


    list_del(&HS3);
    printf("%d %d %d\n",HS0.prev, HS0.next, &HS0);
    printf("%d %d %d\n",HS1.prev, HS1.next, &HS1);
    printf("%d %d %d\n",HS2.prev, HS2.next, &HS2);
}
#endif

//ex4
#if 0
//一个简单的随机生成一个长度的链表并计算长度的程序
#include <iostream>
#include <cstdlib>
#include <cstdio>
#include <ctime>
#include "list.h"

using namespace std;

void randlength( list_entry_t *&elm )
{
    list_init(elm);
    int countt = rand()%100;

    printf("the length of the list that will be created: %d\n", countt );

    for( int i = 0; i < countt; i++  )
    {
        list_entry_t * node = new list_entry_t();
        list_add_after(elm, node);
    }
}

int getlength( list_entry_t *&elm )
{
    int countt = 0;
    list_entry_t * current_node = elm;
    while( current_node->next!=elm )
    {
        countt ++;
        current_node = current_node->next;
    }
    return countt;
}

int main()
{
    srand( (unsigned)time(NULL));
    list_entry_t * root = new list_entry_t();
    randlength( root );
    printf(" the length of this list is %d", getlength(root) );

    return 0;
}
#endif
