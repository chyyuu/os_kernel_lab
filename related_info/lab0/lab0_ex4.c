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
