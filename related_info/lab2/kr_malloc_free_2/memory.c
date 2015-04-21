#include "memory.h"
#include <stdlib.h> /* for malloc */
#include <stdio.h> /* for printf (for debugging) */
#include <string.h> /* for memcpy */
#include <inttypes.h>

const size_t g_totalMemorySize = 1024; /* bytes */
unsigned char *g_heapsBase = NULL;
unsigned char *g_heapsEnd = NULL;

#define TRUE 1
#define FALSE 0
#define BOOLEAN int

#define ALIGN(size) ((size + 7) & ~0x7)

typedef struct block * BlockPtr;
struct block
{
  BOOLEAN  isFree;
  size_t   size;
  BlockPtr next;
  BlockPtr previous;
  char     data[1]; /* marks the start of the actual data segment */
};
const HEADER_SIZE = offsetof(struct block, data);

static int _assert(BOOLEAN condition, int line); /* for line, pass in __LINE__ */
static BlockPtr _findBlock( /*BlockPtr last, */ size_t size);
static void _splitBlock(BlockPtr b, size_t size);
static void _initHeap();
static BOOLEAN _isValidAddress(void *ptr);

void memoryDump()
{
  BlockPtr b = NULL;
  unsigned char * p = NULL;
  int col = 0;
  unsigned char * snapshot = (unsigned char *)malloc(g_totalMemorySize);

  printf("\n----------- heap metadata --------------\n");
  printf("Our heap's total size: %zd\n", g_totalMemorySize);
  printf("HEADER_SIZE: %d\n", HEADER_SIZE);
  printf("So max total net available memory is: %zd\n\n", g_totalMemorySize - HEADER_SIZE);
  memcpy(snapshot, g_heapsBase, g_totalMemorySize);

  /*
   * Make headers human-readable
   */
  int blockCounter = 0;
  for (b = (BlockPtr) g_heapsBase; b != NULL; b = b->next)
  {
    /*
     * Pad the number with spaces so the whole message is the size of the header:
     * 32 bytes on a 64-bit machine (should be 28 bytes but 32 because of alignment?  or am I miscounting?)
     * 16 bytes on a 32-bit machine.
     */
    char msg[100];
    sprintf(msg, "[%16zd bytes:       ]", b->size);

    size_t offset = (unsigned char*)b - (unsigned char*)g_heapsBase;
    _assert(offset >= 0 && offset < g_totalMemorySize, __LINE__);
    
    memcpy((unsigned char*)((size_t)snapshot + offset), msg, HEADER_SIZE);

    size_t withHeader = b->size + HEADER_SIZE;
    printf("Block %d, %3zd B (%3zd B) at %p (after header), is %s\n", /* replace the size_t prints %d by %zd on Ubuntu */
      ++blockCounter, 
      b->size, 
      withHeader,
      b->data,
      b->isFree ? "FREE" : "OCCUPIED");
  }
  printf("\n");

  /*
   * Print the heap snapshot
   */
  printf("------------ heap content: beginning memory dump ---------------\n");
  for (p = snapshot; p < (snapshot + g_totalMemorySize); p++)
  {
    if (*p && *p != '\n')
    {
      /* print the symbol at that location as a character */
      putchar(*p);
    }
    else
    {
      putchar(178);
    }
    
    /* insert periodic line breaks */
    col++;
    if (col % 64 == 0)
    {
      putchar('\n');
    }
  }

  printf("------------- ending memory dump :heap content -----------------\n\n");
}

static void _initHeap()
{
  g_heapsBase = malloc(g_totalMemorySize);
  g_heapsEnd = g_heapsBase + g_totalMemorySize;

  /* initially, the heap is one giant block (which gets divvied up and fragmented over time as people make dcmalloc requests) */
  BlockPtr newBlock;
  newBlock = (BlockPtr)(g_heapsBase);
  newBlock->size = g_totalMemorySize - HEADER_SIZE;
  newBlock->isFree = TRUE;
  newBlock->next = NULL;
  newBlock->previous = NULL;
}

/**
* assuming we still have memory left
* TO DO: add an _assert()
*/
void * dcmalloc(size_t size)
{
  BlockPtr b = NULL;

  size = ALIGN(size);

  if (!g_heapsBase)
  {
    _initHeap();
  }

  b = _findBlock(size);
  if (!b)
  {
    printf("Sorry, not enough memory left to allocate %zd bytes.\n", size);
    return NULL;
  }
  b->isFree = FALSE;
  _splitBlock(b, size);

  printf("allocating at %p, %zd bytes\n", b, size);
  return b->data;
}

void _merge(BlockPtr b, BlockPtr nextBlock)
{
  /* assume b1 and b2 are neighbors, both are free, and b1 is right before b2 */
  _assert(b->isFree && nextBlock->isFree, __LINE__); /* both blocks think they are free */
  _assert(b->next == nextBlock, __LINE__); /* b1 thinks that b2 is after her */
  _assert(b == nextBlock->previous, __LINE__); /* b2 thinks that b1 is before him */
  _assert(b < nextBlock, __LINE__); /* b1 is before b2 */

  b->size += (HEADER_SIZE + nextBlock->size);
  b->next = nextBlock->next; /* skip next block */
  if (nextBlock->next)
  {
    nextBlock->next->previous = b;
  }

  memset(b->data, '-', b->size);
}

/*
 * Important: if ptr is NULL, this will return TRUE.
 *
 * But if ptr is not NULL (i.e. has no excuse) and is
 * not within the bounds of our heap, then this will return FALSE 
 */
BOOLEAN _isValidAddress(void *ptr)
{
  unsigned char *p = (unsigned char *)ptr;

  BOOLEAN isValid = TRUE;

  if (p)
  {
    isValid =
      p <= g_heapsEnd &&
      p >= g_heapsBase;
  }
  return isValid;
}

void dcfree(void *ptr)
{
  BlockPtr b = (BlockPtr) (ptr - HEADER_SIZE);

  printf("freeing %p\n", ptr);
  _assert(b && _isValidAddress(b), __LINE__);
  _assert(_isValidAddress(b->next), __LINE__);
  _assert(_isValidAddress(b->previous), __LINE__);

  b->isFree = TRUE;
  dcmemset(b->data, '-', b->size);
 
  /* fuse with the next block if it's also free */
  if (b->next)
  {
    if (b->next->isFree)
    {
      _merge(b, b->next);
    }
  }

  if (b->previous && b->previous->isFree)
  {
    _merge(b->previous, b);
  }
}


void * dcmemset(void * ptr, int value, size_t num)
{
  int c = value;
  size_t i = 0;
  unsigned char *p = (unsigned char *)ptr;

  for (i = 0; i < num; i++)
  {
    *p = (unsigned char)c;
    p++;
  }

  return ptr;
}

static BlockPtr _findBlock( size_t size )
{
  BlockPtr b = (BlockPtr) g_heapsBase;
  _assert(b != NULL, __LINE__);
  while (b && !(b->isFree && size <= b->size))
  {
    b = b->next;
  }
  return b;
}


/*
 * Arguments:
 *  size - size without the header; i.e. how much data, at a minimum, do you need this block to hold?
 *  b    - block to split
 *
 * The simple picture:
 *  Before: |------------------ block b ------------------|
 *  After:  |--- block b ---|--------- new block ---------|
 *
 * Or, to be more precise, with headers (marked with an 'H'):
 *  Before: |H----------------- block b ------------------|
 *  After:  |H-- block b ---|H-------- new block ---------|
 */
static void _splitBlock(BlockPtr b, size_t size)
{
  if (size >= b->size)
  {
    return;
  }

  /* create a second block */
  BlockPtr newBlock;
  unsigned char *p = b->data + size;
  newBlock = (BlockPtr)p;
  newBlock->size = b->size - size - HEADER_SIZE;
  newBlock->next = b->next;
  newBlock->previous = b;
  newBlock->isFree = TRUE;

  /* update the original block */
  b->size = size;
  b->next = newBlock;

  /* debug */
  _assert((unsigned char*) newBlock->next < g_heapsEnd, __LINE__);
  if ((unsigned char *) newBlock->next >= g_heapsEnd)
  {
    printf("splitBlock: invalid address!");
    getchar();
    return;
  }

  _assert((unsigned char *) b->next < g_heapsEnd, __LINE__);
  if ((unsigned char *) b->next >= g_heapsEnd)
  {
    printf("splitBlock: invalid address 2!");
    getchar();
    return;
  }
}



static int _assert(BOOLEAN condition, int line)
{
  if (!condition)
  {
    fprintf(stderr,
      "_assertION FAILURE: at %s, line %d\n",
      __FILE__,
      line);
    return FALSE;
  }
  return TRUE;
}
