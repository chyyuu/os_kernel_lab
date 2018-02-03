#include "emulation.h"
#include "fp_emulation.h"
#include "unprivileged_memory.h"
#include "mtrap.h"
#include "config.h"
#include "pk.h"

union byte_array {
  uint8_t bytes[8];
  uintptr_t intx;
  uint64_t int64;
};

void misaligned_load_trap(uintptr_t* regs, uintptr_t mcause, uintptr_t mepc)
{
  union byte_array val;
  uintptr_t mstatus;
  insn_t insn = get_insn(mepc, &mstatus);
  uintptr_t npc = mepc + insn_len(insn);
  uintptr_t addr = read_csr(mbadaddr);

  int shift = 0, fp = 0, len;
  if ((insn & MASK_LW) == MATCH_LW)
    len = 4, shift = 8*(sizeof(uintptr_t) - len);
#if __riscv_xlen == 64
  else if ((insn & MASK_LD) == MATCH_LD)
    len = 8, shift = 8*(sizeof(uintptr_t) - len);
  else if ((insn & MASK_LWU) == MATCH_LWU)
    len = 4;
#endif
#ifdef PK_ENABLE_FP_EMULATION
  else if ((insn & MASK_FLD) == MATCH_FLD)
    fp = 1, len = 8;
  else if ((insn & MASK_FLW) == MATCH_FLW)
    fp = 1, len = 4;
#endif
  else if ((insn & MASK_LH) == MATCH_LH)
    len = 2, shift = 8*(sizeof(uintptr_t) - len);
  else if ((insn & MASK_LHU) == MATCH_LHU)
    len = 2;
#ifdef __riscv_compressed
# if __riscv_xlen >= 64
  else if ((insn & MASK_C_LD) == MATCH_C_LD)
    len = 8, shift = 8*(sizeof(uintptr_t) - len), insn = RVC_RS2S(insn) << SH_RD;
  else if ((insn & MASK_C_LDSP) == MATCH_C_LDSP && ((insn >> SH_RD) & 0x1f))
    len = 8, shift = 8*(sizeof(uintptr_t) - len);
# endif
  else if ((insn & MASK_C_LW) == MATCH_C_LW)
    len = 4, shift = 8*(sizeof(uintptr_t) - len), insn = RVC_RS2S(insn) << SH_RD;
  else if ((insn & MASK_C_LWSP) == MATCH_C_LWSP && ((insn >> SH_RD) & 0x1f))
    len = 4, shift = 8*(sizeof(uintptr_t) - len);
# ifdef PK_ENABLE_FP_EMULATION
  else if ((insn & MASK_C_FLD) == MATCH_C_FLD)
    fp = 1, len = 8, insn = RVC_RS2S(insn) << SH_RD;
  else if ((insn & MASK_C_FLDSP) == MATCH_C_FLDSP)
    fp = 1, len = 8;
#  if __riscv_xlen == 32
  else if ((insn & MASK_C_FLW) == MATCH_C_FLW)
    fp = 1, len = 4, insn = RVC_RS2S(insn) << SH_RD;
  else if ((insn & MASK_C_FLWSP) == MATCH_C_FLWSP)
    fp = 1, len = 4;
#  endif
# endif
#endif
  else
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  val.int64 = 0;
  for (intptr_t i = 0; i < len; i++)
    val.bytes[i] = load_uint8_t((void *)(addr + i), mepc);

  if (!fp)
    SET_RD(insn, regs, (intptr_t)val.intx << shift >> shift);
  else if (len == 8)
    SET_F64_RD(insn, regs, val.int64);
  else
    SET_F32_RD(insn, regs, val.intx);

  write_csr(mepc, npc);
}

void misaligned_store_trap(uintptr_t* regs, uintptr_t mcause, uintptr_t mepc)
{
  union byte_array val;
  uintptr_t mstatus;
  insn_t insn = get_insn(mepc, &mstatus);
  uintptr_t npc = mepc + insn_len(insn);
  int len;

  val.intx = GET_RS2(insn, regs);
  if ((insn & MASK_SW) == MATCH_SW)
    len = 4;
#if __riscv_xlen == 64
  else if ((insn & MASK_SD) == MATCH_SD)
    len = 8;
#endif
#ifdef PK_ENABLE_FP_EMULATION
  else if ((insn & MASK_FSD) == MATCH_FSD)
    len = 8, val.int64 = GET_F64_RS2(insn, regs);
  else if ((insn & MASK_FSW) == MATCH_FSW)
    len = 4, val.intx = GET_F32_RS2(insn, regs);
#endif
  else if ((insn & MASK_SH) == MATCH_SH)
    len = 2;
#ifdef __riscv_compressed
# if __riscv_xlen >= 64
  else if ((insn & MASK_C_SD) == MATCH_C_SD)
    len = 8, val.intx = GET_RS2S(insn, regs);
  else if ((insn & MASK_C_SDSP) == MATCH_C_SDSP && ((insn >> SH_RD) & 0x1f))
    len = 8, val.intx = GET_RS2C(insn, regs);
# endif
  else if ((insn & MASK_C_SW) == MATCH_C_SW)
    len = 4, val.intx = GET_RS2S(insn, regs);
  else if ((insn & MASK_C_SWSP) == MATCH_C_SWSP && ((insn >> SH_RD) & 0x1f))
    len = 4, val.intx = GET_RS2C(insn, regs);
# ifdef PK_ENABLE_FP_EMULATION
  else if ((insn & MASK_C_FSD) == MATCH_C_FSD)
    len = 8, val.int64 = GET_F64_RS2S(insn, regs);
  else if ((insn & MASK_C_FSDSP) == MATCH_C_FSDSP)
    len = 8, val.int64 = GET_F64_RS2C(insn, regs);
#  if __riscv_xlen == 32
  else if ((insn & MASK_C_FSW) == MATCH_C_FSW)
    len = 4, val.intx = GET_F32_RS2S(insn, regs);
  else if ((insn & MASK_C_FSWSP) == MATCH_C_FSWSP)
    len = 4, val.intx = GET_F32_RS2C(insn, regs);
#  endif
# endif
#endif
  else
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  uintptr_t addr = read_csr(mbadaddr);
  for (int i = 0; i < len; i++)
    store_uint8_t((void *)(addr + i), val.bytes[i], mepc);

  write_csr(mepc, npc);
}
