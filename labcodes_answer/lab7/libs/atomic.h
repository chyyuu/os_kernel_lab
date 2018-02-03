#ifndef __LIBS_ATOMIC_H__
#define __LIBS_ATOMIC_H__

/* Atomic operations that C can't guarantee us. Useful for resource counting
 * etc.. */

static inline void set_bit(int nr, volatile void *addr)
    __attribute__((always_inline));
static inline void clear_bit(int nr, volatile void *addr)
    __attribute__((always_inline));
static inline void change_bit(int nr, volatile void *addr)
    __attribute__((always_inline));
static inline bool test_bit(int nr, volatile void *addr)
    __attribute__((always_inline));
static inline bool test_and_set_bit(int nr, volatile void *addr)
    __attribute__((always_inline));
static inline bool test_and_clear_bit(int nr, volatile void *addr)
    __attribute__((always_inline));

#define BITS_PER_LONG __riscv_xlen

#if (BITS_PER_LONG == 64)
#define __AMO(op) "amo" #op ".d"
#elif (BITS_PER_LONG == 32)
#define __AMO(op) "amo" #op ".w"
#else
#error "Unexpected BITS_PER_LONG"
#endif

#define BIT_MASK(nr) (1UL << ((nr) % BITS_PER_LONG))
#define BIT_WORD(nr) ((nr) / BITS_PER_LONG)

#define __test_and_op_bit(op, mod, nr, addr)                         \
    ({                                                               \
        unsigned long __res, __mask;                                 \
        __mask = BIT_MASK(nr);                                       \
        __asm__ __volatile__(__AMO(op) " %0, %2, %1"                 \
                             : "=r"(__res), "+A"(addr[BIT_WORD(nr)]) \
                             : "r"(mod(__mask)));                    \
        ((__res & __mask) != 0);                                     \
    })

#define __op_bit(op, mod, nr, addr)                 \
    __asm__ __volatile__(__AMO(op) " zero, %1, %0"  \
                         : "+A"(addr[BIT_WORD(nr)]) \
                         : "r"(mod(BIT_MASK(nr))))

/* Bitmask modifiers */
#define __NOP(x) (x)
#define __NOT(x) (~(x))

/* *
 * set_bit - Atomically set a bit in memory
 * @nr:     the bit to set
 * @addr:   the address to start counting from
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
}

/* *
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
}

/* *
 * change_bit - Atomically toggle a bit in memory
 * @nr:     the bit to change
 * @addr:   the address to start counting from
 * */
static inline void change_bit(int nr, volatile void *addr) {
    __op_bit (xor, __NOP, nr, ((volatile unsigned long *)addr));
}

/* *
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
}

/* *
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
}

/* *
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
}

#endif /* !__LIBS_ATOMIC_H__ */
