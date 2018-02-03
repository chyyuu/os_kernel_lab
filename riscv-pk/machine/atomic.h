// See LICENSE for license details.

#ifndef _RISCV_ATOMIC_H
#define _RISCV_ATOMIC_H

#include "config.h"
#include "encoding.h"

// Currently, interrupts are always disabled in M-mode.
#define disable_irqsave() (0)
#define enable_irqrestore(flags) ((void) (flags))

typedef struct { int lock; } spinlock_t;
#define SPINLOCK_INIT {0}

#define mb() asm volatile ("fence" ::: "memory")
#define atomic_set(ptr, val) (*(volatile typeof(*(ptr)) *)(ptr) = val)
#define atomic_read(ptr) (*(volatile typeof(*(ptr)) *)(ptr))

#ifdef __riscv_atomic
# define atomic_add(ptr, inc) __sync_fetch_and_add(ptr, inc)
# define atomic_or(ptr, inc) __sync_fetch_and_or(ptr, inc)
# define atomic_swap(ptr, swp) __sync_lock_test_and_set(ptr, swp)
# define atomic_cas(ptr, cmp, swp) __sync_val_compare_and_swap(ptr, cmp, swp)
#else
# define atomic_binop(ptr, inc, op) ({ \
  long flags = disable_irqsave(); \
  typeof(*(ptr)) res = atomic_read(ptr); \
  atomic_set(ptr, op); \
  enable_irqrestore(flags); \
  res; })
# define atomic_add(ptr, inc) atomic_binop(ptr, inc, res + (inc))
# define atomic_or(ptr, inc) atomic_binop(ptr, inc, res | (inc))
# define atomic_swap(ptr, inc) atomic_binop(ptr, inc, (inc))
# define atomic_cas(ptr, cmp, swp) ({ \
  long flags = disable_irqsave(); \
  typeof(*(ptr)) res = *(volatile typeof(*(ptr)) *)(ptr); \
  if (res == (cmp)) *(volatile typeof(ptr))(ptr) = (swp); \
  enable_irqrestore(flags); \
  res; })
#endif

static inline int spinlock_trylock(spinlock_t* lock)
{
  int res = atomic_swap(&lock->lock, -1);
  mb();
  return res;
}

static inline void spinlock_lock(spinlock_t* lock)
{
  do
  {
    while (atomic_read(&lock->lock))
      ;
  } while (spinlock_trylock(lock));
}

static inline void spinlock_unlock(spinlock_t* lock)
{
  mb();
  atomic_set(&lock->lock,0);
}

static inline long spinlock_lock_irqsave(spinlock_t* lock)
{
  long flags = disable_irqsave();
  spinlock_lock(lock);
  return flags;
}

static inline void spinlock_unlock_irqrestore(spinlock_t* lock, long flags)
{
  spinlock_unlock(lock);
  enable_irqrestore(flags);
}

#endif
