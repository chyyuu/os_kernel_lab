#ifndef MEMORY_H_
#define MEMORY_H_

#include <stddef.h> /* for size_t */

void * dcmalloc(size_t size);
void dcfree(void * ptr);

void * dcmemset(void * ptr, int value, size_t num);

void memoryDump();

#endif
