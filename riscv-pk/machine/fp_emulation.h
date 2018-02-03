#ifndef _RISCV_FP_EMULATION_H
#define _RISCV_FP_EMULATION_H

#include "emulation.h"

#define GET_PRECISION(insn) (((insn) >> 25) & 3)
#define GET_RM(insn) (((insn) >> 12) & 7)
#define PRECISION_S 0
#define PRECISION_D 1

#ifdef __riscv_flen
# define GET_F32_REG(insn, pos, regs) ({ \
  register int32_t value asm("a0") = SHIFT_RIGHT(insn, (pos)-3) & 0xf8; \
  uintptr_t tmp; \
  asm ("1: auipc %0, %%pcrel_hi(get_f32_reg); add %0, %0, %1; jalr t0, %0, %%pcrel_lo(1b)" : "=&r"(tmp), "+&r"(value) :: "t0"); \
  value; })
# define SET_F32_REG(insn, pos, regs, val) ({ \
  register uint32_t value asm("a0") = (val); \
  uintptr_t offset = SHIFT_RIGHT(insn, (pos)-3) & 0xf8; \
  uintptr_t tmp; \
  asm volatile ("1: auipc %0, %%pcrel_hi(put_f32_reg); add %0, %0, %2; jalr t0, %0, %%pcrel_lo(1b)" : "=&r"(tmp) : "r"(value), "r"(offset) : "t0"); })
# define init_fp_reg(i) SET_F32_REG((i) << 3, 3, 0, 0)
# define GET_F64_REG(insn, pos, regs) ({ \
  register uintptr_t value asm("a0") = SHIFT_RIGHT(insn, (pos)-3) & 0xf8; \
  uintptr_t tmp; \
  asm ("1: auipc %0, %%pcrel_hi(get_f64_reg); add %0, %0, %1; jalr t0, %0, %%pcrel_lo(1b)" : "=&r"(tmp), "+&r"(value) :: "t0"); \
  sizeof(uintptr_t) == 4 ? *(int64_t*)value : (int64_t)value; })
# define SET_F64_REG(insn, pos, regs, val) ({ \
  uint64_t __val = (val); \
  register uintptr_t value asm("a0") = sizeof(uintptr_t) == 4 ? (uintptr_t)&__val : (uintptr_t)__val; \
  uintptr_t offset = SHIFT_RIGHT(insn, (pos)-3) & 0xf8; \
  uintptr_t tmp; \
  asm volatile ("1: auipc %0, %%pcrel_hi(put_f64_reg); add %0, %0, %2; jalr t0, %0, %%pcrel_lo(1b)" : "=&r"(tmp) : "r"(value), "r"(offset) : "t0"); })
# define GET_FCSR() read_csr(fcsr)
# define SET_FCSR(value) write_csr(fcsr, (value))
# define GET_FRM() read_csr(frm)
# define SET_FRM(value) write_csr(frm, (value))
# define GET_FFLAGS() read_csr(fflags)
# define SET_FFLAGS(value) write_csr(fflags, (value))

# define SETUP_STATIC_ROUNDING(insn) ({ \
  register long tp asm("tp") = read_csr(frm); \
  if (likely(((insn) & MASK_FUNCT3) == MASK_FUNCT3)) ; \
  else if (GET_RM(insn) > 4) return truly_illegal_insn(regs, mcause, mepc, mstatus, insn); \
  else tp = GET_RM(insn); \
  asm volatile ("":"+r"(tp)); })
# define softfloat_raiseFlags(which) set_csr(fflags, which)
# define softfloat_roundingMode ({ register int tp asm("tp"); tp; })
# define SET_FS_DIRTY() ((void) 0)
#else
# define GET_F64_REG(insn, pos, regs) (*(int64_t*)((void*)((regs) + 32) + (SHIFT_RIGHT(insn, (pos)-3) & 0xf8)))
# define SET_F64_REG(insn, pos, regs, val) (GET_F64_REG(insn, pos, regs) = (val))
# define GET_F32_REG(insn, pos, regs) (*(int32_t*)&GET_F64_REG(insn, pos, regs))
# define SET_F32_REG(insn, pos, regs, val) (GET_F32_REG(insn, pos, regs) = (val))
# define GET_FCSR() ({ register int tp asm("tp"); tp & 0xFF; })
# define SET_FCSR(value) ({ asm volatile("add tp, x0, %0" :: "rI"((value) & 0xFF)); SET_FS_DIRTY(); })
# define GET_FRM() (GET_FCSR() >> 5)
# define SET_FRM(value) SET_FCSR(GET_FFLAGS() | ((value) << 5))
# define GET_FFLAGS() (GET_FCSR() & 0x1F)
# define SET_FFLAGS(value) SET_FCSR((GET_FRM() << 5) | ((value) & 0x1F))

# define SETUP_STATIC_ROUNDING(insn) ({ \
  register int tp asm("tp"); tp &= 0xFF; \
  if (likely(((insn) & MASK_FUNCT3) == MASK_FUNCT3)) tp |= tp << 8; \
  else if (GET_RM(insn) > 4) return truly_illegal_insn(regs, mcause, mepc, mstatus, insn); \
  else tp |= GET_RM(insn) << 13; \
  asm volatile ("":"+r"(tp)); })
# define softfloat_raiseFlags(which) ({ asm volatile ("or tp, tp, %0" :: "rI"(which)); })
# define softfloat_roundingMode ({ register int tp asm("tp"); tp >> 13; })
# define SET_FS_DIRTY() set_csr(mstatus, MSTATUS_FS)
#endif

#define GET_F32_RS1(insn, regs) (GET_F32_REG(insn, 15, regs))
#define GET_F32_RS2(insn, regs) (GET_F32_REG(insn, 20, regs))
#define GET_F32_RS3(insn, regs) (GET_F32_REG(insn, 27, regs))
#define GET_F64_RS1(insn, regs) (GET_F64_REG(insn, 15, regs))
#define GET_F64_RS2(insn, regs) (GET_F64_REG(insn, 20, regs))
#define GET_F64_RS3(insn, regs) (GET_F64_REG(insn, 27, regs))
#define SET_F32_RD(insn, regs, val) (SET_F32_REG(insn, 7, regs, val), SET_FS_DIRTY())
#define SET_F64_RD(insn, regs, val) (SET_F64_REG(insn, 7, regs, val), SET_FS_DIRTY())

#define GET_F32_RS2C(insn, regs) (GET_F32_REG(insn, 2, regs))
#define GET_F32_RS2S(insn, regs) (GET_F32_REG(RVC_RS2S(insn), 0, regs))
#define GET_F64_RS2C(insn, regs) (GET_F64_REG(insn, 2, regs))
#define GET_F64_RS2S(insn, regs) (GET_F64_REG(RVC_RS2S(insn), 0, regs))

#endif
