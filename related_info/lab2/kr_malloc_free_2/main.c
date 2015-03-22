#include "memory.h"
#include <stdio.h>

#define SAFE_FREE(ptr) if (ptr) dcfree(ptr)
#define SAFE_MEMSET(ptr, value, size) if (ptr) dcmemset(ptr, value, size)

int main()
{
  const int
    na = 6,
    nb = 2,
    nc = 912,
    nd = 4;

  char *a = (char *)dcmalloc(na * sizeof( char));
  SAFE_MEMSET(a, 'a', na);
  
  char *b = (char *)dcmalloc(nb * sizeof(char));
  SAFE_MEMSET(b, 'b', nb);

  char *c = (char *)dcmalloc(nc * sizeof(char));
  SAFE_MEMSET(c, 'c', nc);

  SAFE_FREE(c);

  char *d = (char *)dcmalloc(nd * sizeof(char));
  SAFE_MEMSET(d, 'd', nd);

  memoryDump();

  SAFE_FREE(b);
  SAFE_FREE(a);
  SAFE_FREE(d);

  memoryDump();
}
