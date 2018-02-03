#include "emulation.h"

#ifndef __riscv_muldiv

#if __riscv_xlen == 64
typedef __int128 double_int;
#else
typedef int64_t double_int;
#endif

// These routines rely on the compiler to turn these operations into libcalls
// when not natively supported.  So work on making those go fast.

DECLARE_EMULATION_FUNC(emulate_mul_div)
{
  uintptr_t rs1 = GET_RS1(insn, regs), rs2 = GET_RS2(insn, regs), val;

  if ((insn & MASK_MUL) == MATCH_MUL)
    val = rs1 * rs2;
  else if ((insn & MASK_DIV) == MATCH_DIV)
    val = (intptr_t)rs1 / (intptr_t)rs2;
  else if ((insn & MASK_DIVU) == MATCH_DIVU)
    val = rs1 / rs2;
  else if ((insn & MASK_REM) == MATCH_REM)
    val = (intptr_t)rs1 % (intptr_t)rs2;
  else if ((insn & MASK_REMU) == MATCH_REMU)
    val = rs1 % rs2;
  else if ((insn & MASK_MULH) == MATCH_MULH)
    val = ((double_int)(intptr_t)rs1 * (double_int)(intptr_t)rs2) >> (8 * sizeof(rs1));
  else if ((insn & MASK_MULHU) == MATCH_MULHU)
    val = ((double_int)rs1 * (double_int)rs2) >> (8 * sizeof(rs1));
  else if ((insn & MASK_MULHSU) == MATCH_MULHSU)
    val = ((double_int)(intptr_t)rs1 * (double_int)rs2) >> (8 * sizeof(rs1));
  else
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  SET_RD(insn, regs, val);
}

#if __riscv_xlen == 64

DECLARE_EMULATION_FUNC(emulate_mul_div32)
{
  uint32_t rs1 = GET_RS1(insn, regs), rs2 = GET_RS2(insn, regs);
  int32_t val;

  if ((insn & MASK_MULW) == MATCH_MULW)
    val = rs1 * rs2;
  else if ((insn & MASK_DIVW) == MATCH_DIVW)
    val = (int32_t)rs1 / (int32_t)rs2;
  else if ((insn & MASK_DIVUW) == MATCH_DIVUW)
    val = rs1 / rs2;
  else if ((insn & MASK_REMW) == MATCH_REMW)
    val = (int32_t)rs1 % (int32_t)rs2;
  else if ((insn & MASK_REMUW) == MATCH_REMUW)
    val = rs1 % rs2;
  else
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  SET_RD(insn, regs, val);
}

#endif
#endif
