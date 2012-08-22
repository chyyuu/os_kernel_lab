#ifndef __LIBS_ATOMIC_H__
#define __LIBS_ATOMIC_H__

/* Atomic operations that C can't guarantee us. Useful for resource counting etc.. */

typedef struct {
    volatile int counter;
} atomic_t;

static inline int atomic_read(const atomic_t *v) __attribute__((always_inline));
static inline void atomic_set(atomic_t *v, int i) __attribute__((always_inline));
static inline void atomic_add(atomic_t *v, int i) __attribute__((always_inline));
static inline void atomic_sub(atomic_t *v, int i) __attribute__((always_inline));
static inline bool atomic_sub_test_zero(atomic_t *v, int i) __attribute__((always_inline));
static inline void atomic_inc(atomic_t *v) __attribute__((always_inline));
static inline void atomic_dec(atomic_t *v) __attribute__((always_inline));
static inline bool atomic_inc_test_zero(atomic_t *v) __attribute__((always_inline));
static inline bool atomic_dec_test_zero(atomic_t *v) __attribute__((always_inline));
static inline int atomic_add_return(atomic_t *v, int i) __attribute__((always_inline));
static inline int atomic_sub_return(atomic_t *v, int i) __attribute__((always_inline));

/* *
 * atomic_read - read atomic variable
 * @v:  pointer of type atomic_t
 *
 * Atomically reads the value of @v.
 * */
static inline int
atomic_read(const atomic_t *v) {
    return v->counter;
}

/* *
 * atomic_set - set atomic variable
 * @v:  pointer of type atomic_t
 * @i:  required value
 *
 * Atomically sets the value of @v to @i.
 * */
static inline void
atomic_set(atomic_t *v, int i) {
    v->counter = i;
}

/* *
 * atomic_add - add integer to atomic variable
 * @v:  pointer of type atomic_t
 * @i:  integer value to add
 *
 * Atomically adds @i to @v.
 * */
static inline void
atomic_add(atomic_t *v, int i) {
    asm volatile ("addl %1, %0" : "+m" (v->counter) : "ir" (i));
}

/* *
 * atomic_sub - subtract integer from atomic variable
 * @v:  pointer of type atomic_t
 * @i:  integer value to subtract
 *
 * Atomically subtracts @i from @v.
 * */
static inline void
atomic_sub(atomic_t *v, int i) {
    asm volatile("subl %1, %0" : "+m" (v->counter) : "ir" (i));
}

/* *
 * atomic_sub_test_zero - subtract value from variable and test result
 * @v:  pointer of type atomic_t
 * @i:  integer value to subtract
 *
 * Atomically subtracts @i from @v and
 * returns true if the result is zero, or false for all other cases.
 * */
static inline bool
atomic_sub_test_zero(atomic_t *v, int i) {
    unsigned char c;
    asm volatile("subl %2, %0; sete %1" : "+m" (v->counter), "=qm" (c) : "ir" (i) : "memory");
    return c != 0;
}

/* *
 * atomic_inc - increment atomic variable
 * @v:  pointer of type atomic_t
 *
 * Atomically increments @v by 1.
 * */
static inline void
atomic_inc(atomic_t *v) {
    asm volatile("incl %0" : "+m" (v->counter));
}

/* *
 * atomic_dec - decrement atomic variable
 * @v:  pointer of type atomic_t
 *
 * Atomically decrements @v by 1.
 * */
static inline void
atomic_dec(atomic_t *v) {
    asm volatile("decl %0" : "+m" (v->counter));
}

/* *
 * atomic_inc_test_zero - increment and test
 * @v:  pointer of type atomic_t
 *
 * Atomically increments @v by 1 and
 * returns true if the result is zero, or false for all other cases.
 * */
static inline bool
atomic_inc_test_zero(atomic_t *v) {
    unsigned char c;
    asm volatile("incl %0; sete %1" : "+m" (v->counter), "=qm" (c) :: "memory");
    return c != 0;
}

/* *
 * atomic_dec_test_zero - decrement and test
 * @v:  pointer of type atomic_t
 *
 * Atomically decrements @v by 1 and
 * returns true if the result is 0, or false for all other cases.
 * */
static inline bool
atomic_dec_test_zero(atomic_t *v) {
    unsigned char c;
    asm volatile("decl %0; sete %1" : "+m" (v->counter), "=qm" (c) :: "memory");
    return c != 0;
}

/* *
 * atomic_add_return - add integer and return
 * @i:  integer value to add
 * @v:  pointer of type atomic_t
 *
 * Atomically adds @i to @v and returns @i + @v
 * Requires Modern 486+ processor
 * */
static inline int
atomic_add_return(atomic_t *v, int i) {
    int __i = i;
    asm volatile("xaddl %0, %1" : "+r" (i), "+m" (v->counter) :: "memory");
    return i + __i;
}

/* *
 * atomic_sub_return - subtract integer and return
 * @v:  pointer of type atomic_t
 * @i:  integer value to subtract
 *
 * Atomically subtracts @i from @v and returns @v - @i
 * */
static inline int
atomic_sub_return(atomic_t *v, int i) {
    return atomic_add_return(v, -i);
}

static inline void set_bit(int nr, volatile void *addr) __attribute__((always_inline));
static inline void clear_bit(int nr, volatile void *addr) __attribute__((always_inline));
static inline void change_bit(int nr, volatile void *addr) __attribute__((always_inline));
static inline bool test_and_set_bit(int nr, volatile void *addr) __attribute__((always_inline));
static inline bool test_and_clear_bit(int nr, volatile void *addr) __attribute__((always_inline));
static inline bool test_and_change_bit(int nr, volatile void *addr) __attribute__((always_inline));
static inline bool test_bit(int nr, volatile void *addr) __attribute__((always_inline));

/* *
 * set_bit - Atomically set a bit in memory
 * @nr:     the bit to set
 * @addr:   the address to start counting from
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
}

/* *
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
}

/* *
 * change_bit - Atomically toggle a bit in memory
 * @nr:     the bit to change
 * @addr:   the address to start counting from
 * */
static inline void
change_bit(int nr, volatile void *addr) {
    asm volatile ("btcl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
}

/* *
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool
test_and_set_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btsl %2, %1; sbbl %0, %0" : "=r" (oldbit), "=m" (*(volatile long *)addr) : "Ir" (nr) : "memory");
    return oldbit != 0;
}

/* *
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool
test_and_clear_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btrl %2, %1; sbbl %0, %0" : "=r" (oldbit), "=m" (*(volatile long *)addr) : "Ir" (nr) : "memory");
    return oldbit != 0;
}

/* *
 * test_and_change_bit - Atomically change a bit and return its old value
 * @nr:     the bit to change
 * @addr:   the address to count from
 * */
static inline bool
test_and_change_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btcl %2, %1; sbbl %0, %0" : "=r" (oldbit), "=m" (*(volatile long *)addr) : "Ir" (nr) : "memory");
    return oldbit != 0;
}

/* *
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
    return oldbit != 0;
}

#endif /* !__LIBS_ATOMIC_H__ */

