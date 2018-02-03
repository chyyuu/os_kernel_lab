#include "fp_emulation.h"
#include "unprivileged_memory.h"

#define punt_to_misaligned_handler(align, handler) \
  if (addr % (align) != 0) \
    return write_csr(mbadaddr, addr), (handler)(regs, mcause, mepc)

DECLARE_EMULATION_FUNC(emulate_float_load)
{
  uintptr_t addr = GET_RS1(insn, regs) + IMM_I(insn);

  // if FPU is disabled, punt back to the OS
  if (unlikely((mstatus & MSTATUS_FS) == 0))
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
  
  switch (insn & MASK_FUNCT3)
  {
    case MATCH_FLW & MASK_FUNCT3:
      punt_to_misaligned_handler(4, misaligned_load_trap);
      SET_F32_RD(insn, regs, load_int32_t((void *)addr, mepc));
      break;

    case MATCH_FLD & MASK_FUNCT3:
      punt_to_misaligned_handler(sizeof(uintptr_t), misaligned_load_trap);
      SET_F64_RD(insn, regs, load_uint64_t((void *)addr, mepc));
      break;

    default:
      return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
  }
}

DECLARE_EMULATION_FUNC(emulate_float_store)
{
  uintptr_t addr = GET_RS1(insn, regs) + IMM_S(insn);

  // if FPU is disabled, punt back to the OS
  if (unlikely((mstatus & MSTATUS_FS) == 0))
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
  
  switch (insn & MASK_FUNCT3)
  {
    case MATCH_FSW & MASK_FUNCT3:
      punt_to_misaligned_handler(4, misaligned_store_trap);
      store_uint32_t((void *)addr, GET_F32_RS2(insn, regs), mepc);
      break;

    case MATCH_FSD & MASK_FUNCT3:
      punt_to_misaligned_handler(sizeof(uintptr_t), misaligned_store_trap);
      store_uint64_t((void *)addr, GET_F64_RS2(insn, regs), mepc);
      break;

    default:
      return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
  }
}

