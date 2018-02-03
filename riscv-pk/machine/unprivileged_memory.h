#ifndef _RISCV_MISALIGNED_H
#define _RISCV_MISALIGNED_H

#include "encoding.h"
#include "bits.h"
#include <stdint.h>

#define DECLARE_UNPRIVILEGED_LOAD_FUNCTION(type, insn)              \
  static inline type load_##type(const type* addr, uintptr_t mepc)  \
  {                                                                 \
    register uintptr_t __mepc asm ("a2") = mepc;                    \
    register uintptr_t __mstatus asm ("a3");                        \
    type val;                                                       \
    asm ("csrrs %0, mstatus, %3\n"                                  \
         #insn " %1, %2\n"                                          \
         "csrw mstatus, %0"                                         \
         : "+&r" (__mstatus), "=&r" (val)                           \
         : "m" (*addr), "r" (MSTATUS_MPRV), "r" (__mepc));          \
    return val;                                                     \
  }

#define DECLARE_UNPRIVILEGED_STORE_FUNCTION(type, insn)                 \
  static inline void store_##type(type* addr, type val, uintptr_t mepc) \
  {                                                                     \
    register uintptr_t __mepc asm ("a2") = mepc;                        \
    register uintptr_t __mstatus asm ("a3");                            \
    asm volatile ("csrrs %0, mstatus, %3\n"                             \
                  #insn " %1, %2\n"                                     \
                  "csrw mstatus, %0"                                    \
                  : "+&r" (__mstatus)                                   \
                  : "r" (val), "m" (*addr), "r" (MSTATUS_MPRV),         \
                    "r" (__mepc));                                      \
  }

DECLARE_UNPRIVILEGED_LOAD_FUNCTION(uint8_t, lbu)
DECLARE_UNPRIVILEGED_LOAD_FUNCTION(uint16_t, lhu)
DECLARE_UNPRIVILEGED_LOAD_FUNCTION(int8_t, lb)
DECLARE_UNPRIVILEGED_LOAD_FUNCTION(int16_t, lh)
DECLARE_UNPRIVILEGED_LOAD_FUNCTION(int32_t, lw)
DECLARE_UNPRIVILEGED_STORE_FUNCTION(uint8_t, sb)
DECLARE_UNPRIVILEGED_STORE_FUNCTION(uint16_t, sh)
DECLARE_UNPRIVILEGED_STORE_FUNCTION(uint32_t, sw)
#if __riscv_xlen == 64
DECLARE_UNPRIVILEGED_LOAD_FUNCTION(uint32_t, lwu)
DECLARE_UNPRIVILEGED_LOAD_FUNCTION(uint64_t, ld)
DECLARE_UNPRIVILEGED_STORE_FUNCTION(uint64_t, sd)
DECLARE_UNPRIVILEGED_LOAD_FUNCTION(uintptr_t, ld)
#else
DECLARE_UNPRIVILEGED_LOAD_FUNCTION(uint32_t, lw)
DECLARE_UNPRIVILEGED_LOAD_FUNCTION(uintptr_t, lw)

static inline uint64_t load_uint64_t(const uint64_t* addr, uintptr_t mepc)
{
  return load_uint32_t((uint32_t*)addr, mepc)
         + ((uint64_t)load_uint32_t((uint32_t*)addr + 1, mepc) << 32);
}

static inline void store_uint64_t(uint64_t* addr, uint64_t val, uintptr_t mepc)
{
  store_uint32_t((uint32_t*)addr, val, mepc);
  store_uint32_t((uint32_t*)addr + 1, val >> 32, mepc);
}
#endif

static uintptr_t __attribute__((always_inline)) get_insn(uintptr_t mepc, uintptr_t* mstatus)
{
  register uintptr_t __mepc asm ("a2") = mepc;
  register uintptr_t __mstatus asm ("a3");
  uintptr_t val;
#ifndef __riscv_compressed
  asm ("csrrs %[mstatus], mstatus, %[mprv]\n"
       STR(LWU) " %[insn], (%[addr])\n"
       "csrw mstatus, %[mstatus]"
       : [mstatus] "+&r" (__mstatus), [insn] "=&r" (val)
       : [mprv] "r" (MSTATUS_MPRV | MSTATUS_MXR), [addr] "r" (__mepc));
#else
  uintptr_t rvc_mask = 3, tmp;
  asm ("csrrs %[mstatus], mstatus, %[mprv]\n"
       "and %[tmp], %[addr], 2\n"
       "bnez %[tmp], 1f\n"
       STR(LWU) " %[insn], (%[addr])\n"
       "and %[tmp], %[insn], %[rvc_mask]\n"
       "beq %[tmp], %[rvc_mask], 2f\n"
       "sll %[insn], %[insn], %[xlen_minus_16]\n"
       "srl %[insn], %[insn], %[xlen_minus_16]\n"
       "j 2f\n"
       "1:\n"
       "lhu %[insn], (%[addr])\n"
       "and %[tmp], %[insn], %[rvc_mask]\n"
       "bne %[tmp], %[rvc_mask], 2f\n"
       "lhu %[tmp], 2(%[addr])\n"
       "sll %[tmp], %[tmp], 16\n"
       "add %[insn], %[insn], %[tmp]\n"
       "2: csrw mstatus, %[mstatus]"
       : [mstatus] "+&r" (__mstatus), [insn] "=&r" (val), [tmp] "=&r" (tmp)
       : [mprv] "r" (MSTATUS_MPRV | MSTATUS_MXR), [addr] "r" (__mepc),
         [rvc_mask] "r" (rvc_mask), [xlen_minus_16] "i" (__riscv_xlen - 16));
#endif
  *mstatus = __mstatus;
  return val;
}

#endif
