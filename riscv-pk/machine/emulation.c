#include "emulation.h"
#include "fp_emulation.h"
#include "config.h"
#include "unprivileged_memory.h"
#include "mtrap.h"
#include <limits.h>

static DECLARE_EMULATION_FUNC(emulate_rvc)
{
#ifdef __riscv_compressed
  // the only emulable RVC instructions are FP loads and stores.
# if !defined(__riscv_flen) && defined(PK_ENABLE_FP_EMULATION)
  write_csr(mepc, mepc + 2);

  // if FPU is disabled, punt back to the OS
  if (unlikely((mstatus & MSTATUS_FS) == 0))
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  if ((insn & MASK_C_FLD) == MATCH_C_FLD) {
    uintptr_t addr = GET_RS1S(insn, regs) + RVC_LD_IMM(insn);
    if (unlikely(addr % sizeof(uintptr_t)))
      return misaligned_load_trap(regs, mcause, mepc);
    SET_F64_RD(RVC_RS2S(insn) << SH_RD, regs, load_uint64_t((void *)addr, mepc));
  } else if ((insn & MASK_C_FLDSP) == MATCH_C_FLDSP) {
    uintptr_t addr = GET_SP(regs) + RVC_LDSP_IMM(insn);
    if (unlikely(addr % sizeof(uintptr_t)))
      return misaligned_load_trap(regs, mcause, mepc);
    SET_F64_RD(insn, regs, load_uint64_t((void *)addr, mepc));
  } else if ((insn & MASK_C_FSD) == MATCH_C_FSD) {
    uintptr_t addr = GET_RS1S(insn, regs) + RVC_LD_IMM(insn);
    if (unlikely(addr % sizeof(uintptr_t)))
      return misaligned_store_trap(regs, mcause, mepc);
    store_uint64_t((void *)addr, GET_F64_RS2(RVC_RS2S(insn) << SH_RS2, regs), mepc);
  } else if ((insn & MASK_C_FSDSP) == MATCH_C_FSDSP) {
    uintptr_t addr = GET_SP(regs) + RVC_SDSP_IMM(insn);
    if (unlikely(addr % sizeof(uintptr_t)))
      return misaligned_store_trap(regs, mcause, mepc);
    store_uint64_t((void *)addr, GET_F64_RS2(RVC_RS2(insn) << SH_RS2, regs), mepc);
  } else
#  if __riscv_xlen == 32
  if ((insn & MASK_C_FLW) == MATCH_C_FLW) {
    uintptr_t addr = GET_RS1S(insn, regs) + RVC_LW_IMM(insn);
    if (unlikely(addr % 4))
      return misaligned_load_trap(regs, mcause, mepc);
    SET_F32_RD(RVC_RS2S(insn) << SH_RD, regs, load_int32_t((void *)addr, mepc));
  } else if ((insn & MASK_C_FLWSP) == MATCH_C_FLWSP) {
    uintptr_t addr = GET_SP(regs) + RVC_LWSP_IMM(insn);
    if (unlikely(addr % 4))
      return misaligned_load_trap(regs, mcause, mepc);
    SET_F32_RD(insn, regs, load_int32_t((void *)addr, mepc));
  } else if ((insn & MASK_C_FSW) == MATCH_C_FSW) {
    uintptr_t addr = GET_RS1S(insn, regs) + RVC_LW_IMM(insn);
    if (unlikely(addr % 4))
      return misaligned_store_trap(regs, mcause, mepc);
    store_uint32_t((void *)addr, GET_F32_RS2(RVC_RS2S(insn) << SH_RS2, regs), mepc);
  } else if ((insn & MASK_C_FSWSP) == MATCH_C_FSWSP) {
    uintptr_t addr = GET_SP(regs) + RVC_SWSP_IMM(insn);
    if (unlikely(addr % 4))
      return misaligned_store_trap(regs, mcause, mepc);
    store_uint32_t((void *)addr, GET_F32_RS2(RVC_RS2(insn) << SH_RS2, regs), mepc);
  } else
#  endif
# endif
#endif

  return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
}

void illegal_insn_trap(uintptr_t* regs, uintptr_t mcause, uintptr_t mepc)
{
  asm (".pushsection .rodata\n"
       "illegal_insn_trap_table:\n"
       "  .word truly_illegal_insn\n"
#if !defined(__riscv_flen) && defined(PK_ENABLE_FP_EMULATION)
       "  .word emulate_float_load\n"
#else
       "  .word truly_illegal_insn\n"
#endif
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
#if !defined(__riscv_flen) && defined(PK_ENABLE_FP_EMULATION)
       "  .word emulate_float_store\n"
#else
       "  .word truly_illegal_insn\n"
#endif
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
#if !defined(__riscv_muldiv)
       "  .word emulate_mul_div\n"
#else
       "  .word truly_illegal_insn\n"
#endif
       "  .word truly_illegal_insn\n"
#if !defined(__riscv_muldiv) && __riscv_xlen >= 64
       "  .word emulate_mul_div32\n"
#else
       "  .word truly_illegal_insn\n"
#endif
       "  .word truly_illegal_insn\n"
#ifdef PK_ENABLE_FP_EMULATION
       "  .word emulate_fmadd\n"
       "  .word emulate_fmadd\n"
       "  .word emulate_fmadd\n"
       "  .word emulate_fmadd\n"
       "  .word emulate_fp\n"
#else
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
#endif
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word emulate_system_opcode\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .popsection");

  uintptr_t mstatus = read_csr(mstatus);
  insn_t insn = read_csr(mbadaddr);

  if (unlikely((insn & 3) != 3)) {
    if (insn == 0)
      insn = get_insn(mepc, &mstatus);
    if ((insn & 3) != 3)
      return emulate_rvc(regs, mcause, mepc, mstatus, insn);
  }

  write_csr(mepc, mepc + 4);

  extern uint32_t illegal_insn_trap_table[];
  uint32_t* pf = (void*)illegal_insn_trap_table + (insn & 0x7c);
  emulation_func f = (emulation_func)(uintptr_t)*pf;
  f(regs, mcause, mepc, mstatus, insn);
}

__attribute__((noinline))
DECLARE_EMULATION_FUNC(truly_illegal_insn)
{
  return redirect_trap(mepc, mstatus, insn);
}

static inline int emulate_read_csr(int num, uintptr_t mstatus, uintptr_t* result)
{
  uintptr_t counteren = -1;
  if (EXTRACT_FIELD(mstatus, MSTATUS_MPP) == PRV_U)
    counteren = read_csr(scounteren);

  switch (num)
  {
    case CSR_TIME:
      if (!((counteren >> (CSR_TIME - CSR_CYCLE)) & 1))
        return -1;
      *result = *mtime;
      return 0;
#if __riscv_xlen == 32
    case CSR_TIMEH:
      if (!((counteren >> (CSR_TIME - CSR_CYCLE)) & 1))
        return -1;
      *result = *mtime >> 32;
      return 0;
#endif
#if !defined(__riscv_flen) && defined(PK_ENABLE_FP_EMULATION)
    case CSR_FRM:
      if ((mstatus & MSTATUS_FS) == 0) break;
      *result = GET_FRM();
      return 0;
    case CSR_FFLAGS:
      if ((mstatus & MSTATUS_FS) == 0) break;
      *result = GET_FFLAGS();
      return 0;
    case CSR_FCSR:
      if ((mstatus & MSTATUS_FS) == 0) break;
      *result = GET_FCSR();
      return 0;
#endif
  }
  return -1;
}

static inline int emulate_write_csr(int num, uintptr_t value, uintptr_t mstatus)
{
  switch (num)
  {
#if !defined(__riscv_flen) && defined(PK_ENABLE_FP_EMULATION)
    case CSR_FRM: SET_FRM(value); return 0;
    case CSR_FFLAGS: SET_FFLAGS(value); return 0;
    case CSR_FCSR: SET_FCSR(value); return 0;
#endif
  }
  return -1;
}

DECLARE_EMULATION_FUNC(emulate_system_opcode)
{
  int rs1_num = (insn >> 15) & 0x1f;
  uintptr_t rs1_val = GET_RS1(insn, regs);
  int csr_num = (uint32_t)insn >> 20;
  uintptr_t csr_val, new_csr_val;

  if (emulate_read_csr(csr_num, mstatus, &csr_val))
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  int do_write = rs1_num;
  switch (GET_RM(insn))
  {
    case 0: return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
    case 1: new_csr_val = rs1_val; do_write = 1; break;
    case 2: new_csr_val = csr_val | rs1_val; break;
    case 3: new_csr_val = csr_val & ~rs1_val; break;
    case 4: return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
    case 5: new_csr_val = rs1_num; do_write = 1; break;
    case 6: new_csr_val = csr_val | rs1_num; break;
    case 7: new_csr_val = csr_val & ~rs1_num; break;
  }

  if (do_write && emulate_write_csr(csr_num, new_csr_val, mstatus))
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  SET_RD(insn, regs, csr_val);
}
