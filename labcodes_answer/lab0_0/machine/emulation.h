#ifndef _RISCV_EMULATION_H
#define _RISCV_EMULATION_H

#include "encoding.h"
#include "bits.h"
#include <stdint.h>

typedef uintptr_t insn_t;
typedef void (*emulation_func)(uintptr_t*, uintptr_t, uintptr_t, uintptr_t, insn_t);
#define DECLARE_EMULATION_FUNC(name) void name(uintptr_t* regs, uintptr_t mcause, uintptr_t mepc, uintptr_t mstatus, insn_t insn)

void misaligned_load_trap(uintptr_t* regs, uintptr_t mcause, uintptr_t mepc);
void misaligned_store_trap(uintptr_t* regs, uintptr_t mcause, uintptr_t mepc);
void redirect_trap(uintptr_t epc, uintptr_t mstatus, uintptr_t badaddr);
DECLARE_EMULATION_FUNC(truly_illegal_insn);
DECLARE_EMULATION_FUNC(emulate_rvc_0);
DECLARE_EMULATION_FUNC(emulate_rvc_2);

#define SH_RD 7
#define SH_RS1 15
#define SH_RS2 20
#define SH_RS2C 2

#define RV_X(x, s, n) (((x) >> (s)) & ((1 << (n)) - 1))
#define RVC_LW_IMM(x) ((RV_X(x, 6, 1) << 2) | (RV_X(x, 10, 3) << 3) | (RV_X(x, 5, 1) << 6))
#define RVC_LD_IMM(x) ((RV_X(x, 10, 3) << 3) | (RV_X(x, 5, 2) << 6))
#define RVC_LWSP_IMM(x) ((RV_X(x, 4, 3) << 2) | (RV_X(x, 12, 1) << 5) | (RV_X(x, 2, 2) << 6))
#define RVC_LDSP_IMM(x) ((RV_X(x, 5, 2) << 3) | (RV_X(x, 12, 1) << 5) | (RV_X(x, 2, 3) << 6))
#define RVC_SWSP_IMM(x) ((RV_X(x, 9, 4) << 2) | (RV_X(x, 7, 2) << 6))
#define RVC_SDSP_IMM(x) ((RV_X(x, 10, 3) << 3) | (RV_X(x, 7, 3) << 6))
#define RVC_RS1S(insn) (8 + RV_X(insn, SH_RD, 3))
#define RVC_RS2S(insn) (8 + RV_X(insn, SH_RS2C, 3))
#define RVC_RS2(insn) RV_X(insn, SH_RS2C, 5)

#define SHIFT_RIGHT(x, y) ((y) < 0 ? ((x) << -(y)) : ((x) >> (y)))
#define GET_REG(insn, pos, regs) ({ \
  int mask = (1 << (5+LOG_REGBYTES)) - (1 << LOG_REGBYTES); \
  (uintptr_t*)((uintptr_t)regs + (SHIFT_RIGHT(insn, (pos) - LOG_REGBYTES) & (mask))); \
})
#define GET_RS1(insn, regs) (*GET_REG(insn, SH_RS1, regs))
#define GET_RS2(insn, regs) (*GET_REG(insn, SH_RS2, regs))
#define GET_RS1S(insn, regs) (*GET_REG(RVC_RS1S(insn), 0, regs))
#define GET_RS2S(insn, regs) (*GET_REG(RVC_RS2S(insn), 0, regs))
#define GET_RS2C(insn, regs) (*GET_REG(insn, SH_RS2C, regs))
#define GET_SP(regs) (*GET_REG(2, 0, regs))
#define SET_RD(insn, regs, val) (*GET_REG(insn, SH_RD, regs) = (val))
#define IMM_I(insn) ((int32_t)(insn) >> 20)
#define IMM_S(insn) (((int32_t)(insn) >> 25 << 5) | (int32_t)(((insn) >> 7) & 0x1f))
#define MASK_FUNCT3 0x7000

#endif
