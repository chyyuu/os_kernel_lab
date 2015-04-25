#ifndef __BUDDY2_H__
#define __BUDDY2_H__

#include <stdlib.h>

struct buddy2 {
  unsigned size;
  unsigned longest[0];
};

#define LEFT_LEAF(index) ((index) * 2 + 1)
#define RIGHT_LEAF(index) ((index) * 2 + 2)
#define PARENT(index) ( ((index) + 1) / 2 - 1)

#define IS_POWER_OF_2(x) (!((x)&((x)-1)))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

#define ALLOC malloc
#define FREE free

struct buddy2;
struct buddy2* buddy2_new( int size );
void buddy2_destroy( struct buddy2* self );

int buddy2_alloc(struct buddy2* self, int size);
void buddy2_free(struct buddy2* self, int offset);

int buddy2_size(struct buddy2* self, int offset);
void buddy2_dump(struct buddy2* self);

#endif//__BUDDY2_H__
