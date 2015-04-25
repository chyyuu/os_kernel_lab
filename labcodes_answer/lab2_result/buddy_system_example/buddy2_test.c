#include "buddy2.h"
#include <stdio.h>
int main() {
  char cmd[80];
  int arg;
  int i;
  int node_size;
  struct buddy2* buddy = buddy2_new(32);
  node_size = buddy->size * 2;
  for(i=0;i<buddy->size*2-1;i++) {
      if ( IS_POWER_OF_2(i+1) ){
        printf(" i %d is power of 2, node_size is %d\n", i, node_size /= 2);
      }
      printf("dump %d, %d\n",i,buddy->longest[i]);
  }

  buddy2_dump(buddy);
  for (;;) {
    scanf("%s %d", cmd, &arg);
    if (strcmp(cmd, "a") == 0) {
      printf("allocated@%d\n", buddy2_alloc(buddy, arg));
      buddy2_dump(buddy);
    } else if (strcmp(cmd, "f") == 0) {
      buddy2_free(buddy, arg);
      buddy2_dump(buddy);
    } else if (strcmp(cmd, "s") == 0) {
      printf("size: %d\n", buddy2_size(buddy, arg));
      buddy2_dump(buddy);
    } else
      buddy2_dump(buddy);
  }
}
