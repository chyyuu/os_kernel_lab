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


//ex5
#if 0
// compile with -nostdinc and explicitly provide header file directories
#include "list.h"
#include <stdio.h>

struct MyDataType {
    list_entry_t list;
    int32_t data;
};

struct MyDataType x, y, z;

void display() {
    printf("x = %lx prev = %lx next = %lx \n", &x.list, x.list.prev, x.list.next); 
    printf("y = %lx prev = %lx next = %lx \n", &y.list, y.list.prev, y.list.next); 
    printf("z = %lx prev = %lx next = %lx \n", &z.list, z.list.prev, z.list.next);
    printf("----------------------------------\n");
}

int main() {
    // initialize
    list_init(&x.list);
    list_init(&y.list);
    list_init(&z.list);

    display(); 

    // insert element
    list_add(&x.list, &y.list);

    display();

    list_add_before(&x.list, &z.list);

    display();

    // delete element
    list_del_init(&x.list);

    display();

    return 0;
}
#endif

//ex6
#if 0
#include <stdio.h>
#include <list.h>

int main() {
    struct list_entry first, second, third;
    list_init(&first);
    list_init(&second);
    list_init(&third);
    printf("Is empty:%d\n", list_empty(&first));
    list_add_after(&first, &second);
    printf("Is empty:%d\n", list_empty(&first));
    list_add_before(&first, &third);
    struct list_entry *temp = &first;
    int num = 0;
    while ((temp = list_prev(temp)) != &first)
        num++;
    printf("Total elem:%d\n", num);
    list_del_init(&second);
    list_del_init(&first);
    printf("Is empty:%d\n", list_empty(&third));
    return 0;
}
#endif

//ex7
#if 0
#include <stdio.h>
#include <list.h>

struct Ints {
  int data;
  list_entry_t le;
};

#define le2struct(ptr) to_struct((ptr), struct Ints, le)
#define to_struct(ptr, type, member) \
  ((type *)((char *)(ptr) - offsetof(type, member)))
#define offsetof(type, member) \
  ((size_t)(&((type *)0)->member))

int main() {
  struct Ints one, two, three, *now_int;
  list_entry_t *now;
  one.data = 1;
  two.data = 2;
  three.data = 3;
  list_init(&one.le);
  list_add_before(&one.le, &two.le);
  list_add_after(&one.le, &three.le);

  now = &two.le;
  while (1) {
    now_int = le2struct(now);
    printf("Current: %d\n", now_int->data);
    now = now->next;
    if (now == &two.le)
      break;
  }

  return 0;
}
//输出
//Current: 2
//Current: 1
//Current: 3
#endif
