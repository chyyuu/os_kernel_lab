#include "fp_emulation.h"
#include "unprivileged_memory.h"
#include "softfloat.h"
#include "config.h"

DECLARE_EMULATION_FUNC(emulate_fp)
{
  asm (".pushsection .rodata\n"
       "fp_emulation_table:\n"
       "  .word emulate_fadd\n"
       "  .word emulate_fsub\n"
       "  .word emulate_fmul\n"
       "  .word emulate_fdiv\n"
       "  .word emulate_fsgnj\n"
       "  .word emulate_fmin\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word emulate_fcvt_ff\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word emulate_fsqrt\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word emulate_fcmp\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word truly_illegal_insn\n"
       "  .word emulate_fcvt_if\n"
       "  .word truly_illegal_insn\n"
       "  .word emulate_fcvt_fi\n"
       "  .word truly_illegal_insn\n"
       "  .word emulate_fmv_if\n"
       "  .word truly_illegal_insn\n"
       "  .word emulate_fmv_fi\n"
       "  .word truly_illegal_insn\n"
       "  .popsection");

  // if FPU is disabled, punt back to the OS
  if (unlikely((mstatus & MSTATUS_FS) == 0))
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  extern uint32_t fp_emulation_table[];
  uint32_t* pf = (void*)fp_emulation_table + ((insn >> 25) & 0x7c);
  emulation_func f = (emulation_func)(uintptr_t)*pf;

  SETUP_STATIC_ROUNDING(insn);
  return f(regs, mcause, mepc, mstatus, insn);
}

void emulate_any_fadd(uintptr_t* regs, uintptr_t mcause, uintptr_t mepc, uintptr_t mstatus, insn_t insn, int32_t neg_b)
{
  if (GET_PRECISION(insn) == PRECISION_S) {
    uint32_t rs1 = GET_F32_RS1(insn, regs);
    uint32_t rs2 = GET_F32_RS2(insn, regs) ^ neg_b;
    SET_F32_RD(insn, regs, f32_add(rs1, rs2));
  } else if (GET_PRECISION(insn) == PRECISION_D) {
    uint64_t rs1 = GET_F64_RS1(insn, regs);
    uint64_t rs2 = GET_F64_RS2(insn, regs) ^ ((uint64_t)neg_b << 32);
    SET_F64_RD(insn, regs, f64_add(rs1, rs2));
  } else {
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
  }
}

DECLARE_EMULATION_FUNC(emulate_fadd)
{
  return emulate_any_fadd(regs, mcause, mepc, mstatus, insn, 0);
}

DECLARE_EMULATION_FUNC(emulate_fsub)
{
  return emulate_any_fadd(regs, mcause, mepc, mstatus, insn, INT32_MIN);
}

DECLARE_EMULATION_FUNC(emulate_fmul)
{
  if (GET_PRECISION(insn) == PRECISION_S) {
    uint32_t rs1 = GET_F32_RS1(insn, regs);
    uint32_t rs2 = GET_F32_RS2(insn, regs);
    SET_F32_RD(insn, regs, f32_mul(rs1, rs2));
  } else if (GET_PRECISION(insn) == PRECISION_D) {
    uint64_t rs1 = GET_F64_RS1(insn, regs);
    uint64_t rs2 = GET_F64_RS2(insn, regs);
    SET_F64_RD(insn, regs, f64_mul(rs1, rs2));
  } else {
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
  }
}

DECLARE_EMULATION_FUNC(emulate_fdiv)
{
  if (GET_PRECISION(insn) == PRECISION_S) {
    uint32_t rs1 = GET_F32_RS1(insn, regs);
    uint32_t rs2 = GET_F32_RS2(insn, regs);
    SET_F32_RD(insn, regs, f32_div(rs1, rs2));
  } else if (GET_PRECISION(insn) == PRECISION_D) {
    uint64_t rs1 = GET_F64_RS1(insn, regs);
    uint64_t rs2 = GET_F64_RS2(insn, regs);
    SET_F64_RD(insn, regs, f64_div(rs1, rs2));
  } else {
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
  }
}

DECLARE_EMULATION_FUNC(emulate_fsqrt)
{
  if ((insn >> 20) & 0x1f)
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  if (GET_PRECISION(insn) == PRECISION_S) {
    SET_F32_RD(insn, regs, f32_sqrt(GET_F32_RS1(insn, regs)));
  } else if (GET_PRECISION(insn) == PRECISION_D) {
    SET_F64_RD(insn, regs, f64_sqrt(GET_F64_RS1(insn, regs)));
  } else {
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
  }
}

DECLARE_EMULATION_FUNC(emulate_fsgnj)
{
  int rm = GET_RM(insn);
  if (rm >= 3)
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  #define DO_FSGNJ(rs1, rs2, rm) ({ \
    typeof(rs1) rs1_sign = (rs1) >> (8*sizeof(rs1)-1); \
    typeof(rs1) rs2_sign = (rs2) >> (8*sizeof(rs1)-1); \
    rs1_sign &= (rm) >> 1; \
    rs1_sign ^= (rm) ^ rs2_sign; \
    ((rs1) << 1 >> 1) | (rs1_sign << (8*sizeof(rs1)-1)); })

  if (GET_PRECISION(insn) == PRECISION_S) {
    uint32_t rs1 = GET_F32_RS1(insn, regs);
    uint32_t rs2 = GET_F32_RS2(insn, regs);
    SET_F32_RD(insn, regs, DO_FSGNJ(rs1, rs2, rm));
  } else if (GET_PRECISION(insn) == PRECISION_D) {
    uint64_t rs1 = GET_F64_RS1(insn, regs);
    uint64_t rs2 = GET_F64_RS2(insn, regs);
    SET_F64_RD(insn, regs, DO_FSGNJ(rs1, rs2, rm));
  } else {
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
  }
}

DECLARE_EMULATION_FUNC(emulate_fmin)
{
  int rm = GET_RM(insn);
  if (rm >= 2)
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  if (GET_PRECISION(insn) == PRECISION_S) {
    uint32_t rs1 = GET_F32_RS1(insn, regs);
    uint32_t rs2 = GET_F32_RS2(insn, regs);
    uint32_t arg1 = rm ? rs2 : rs1;
    uint32_t arg2 = rm ? rs1 : rs2;
    int use_rs1 = f32_lt_quiet(arg1, arg2) || isNaNF32UI(rs2);
    SET_F32_RD(insn, regs, use_rs1 ? rs1 : rs2);
  } else if (GET_PRECISION(insn) == PRECISION_D) {
    uint64_t rs1 = GET_F64_RS1(insn, regs);
    uint64_t rs2 = GET_F64_RS2(insn, regs);
    uint64_t arg1 = rm ? rs2 : rs1;
    uint64_t arg2 = rm ? rs1 : rs2;
    int use_rs1 = f64_lt_quiet(arg1, arg2) || isNaNF64UI(rs2);
    SET_F64_RD(insn, regs, use_rs1 ? rs1 : rs2);
  } else {
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
  }
}

DECLARE_EMULATION_FUNC(emulate_fcvt_ff)
{
  int rs2_num = (insn >> 20) & 0x1f;
  if (GET_PRECISION(insn) == PRECISION_S) {
    if (rs2_num != 1)
      return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
    SET_F32_RD(insn, regs, f64_to_f32(GET_F64_RS1(insn, regs)));
  } else if (GET_PRECISION(insn) == PRECISION_D) {
    if (rs2_num != 0)
      return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
    SET_F64_RD(insn, regs, f32_to_f64(GET_F32_RS1(insn, regs)));
  } else {
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
  }
}

DECLARE_EMULATION_FUNC(emulate_fcvt_fi)
{
  if (GET_PRECISION(insn) != PRECISION_S && GET_PRECISION(insn) != PRECISION_D)
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  int negative = 0;
  uint64_t uint_val = GET_RS1(insn, regs);

  switch ((insn >> 20) & 0x1f)
  {
    case 0: // int32
      negative = (int32_t)uint_val < 0;
      uint_val = (uint32_t)(negative ? -uint_val : uint_val);
      break;
    case 1: // uint32
      uint_val = (uint32_t)uint_val;
      break;
#if __riscv_xlen == 64
    case 2: // int64
      negative = (int64_t)uint_val < 0;
      uint_val = negative ? -uint_val : uint_val;
    case 3: // uint64
      break;
#endif
    default:
      return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
  }

  uint64_t float64 = ui64_to_f64(uint_val);
  if (negative)
    float64 ^= INT64_MIN;

  if (GET_PRECISION(insn) == PRECISION_S)
    SET_F32_RD(insn, regs, f64_to_f32(float64));
  else
    SET_F64_RD(insn, regs, float64);
}

DECLARE_EMULATION_FUNC(emulate_fcvt_if)
{
  int rs2_num = (insn >> 20) & 0x1f;
#if __riscv_xlen == 64
  if (rs2_num >= 4)
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
#else
  if (rs2_num >= 2)
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
#endif

  int64_t float64;
  if (GET_PRECISION(insn) == PRECISION_S)
    float64 = f32_to_f64(GET_F32_RS1(insn, regs));
  else if (GET_PRECISION(insn) == PRECISION_D)
    float64 = GET_F64_RS1(insn, regs);
  else
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  int negative = 0;
  if (float64 < 0) {
    negative = 1;
    float64 ^= INT64_MIN;
  }
  uint64_t uint_val = f64_to_ui64(float64, softfloat_roundingMode, true);
  uint64_t result, limit, limit_result;

  switch (rs2_num)
  {
    case 0: // int32
      if (negative) {
        result = (int32_t)-uint_val;
        limit_result = limit = (uint32_t)INT32_MIN;
      } else {
        result = (int32_t)uint_val;
        limit_result = limit = INT32_MAX;
      }
      break;

    case 1: // uint32
      limit = limit_result = UINT32_MAX;
      if (negative)
        result = limit = 0;
      else
        result = (uint32_t)uint_val;
      break;

    case 2: // int32
      if (negative) {
        result = (int64_t)-uint_val;
        limit_result = limit = (uint64_t)INT64_MIN;
      } else {
        result = (int64_t)uint_val;
        limit_result = limit = INT64_MAX;
      }
      break;

    case 3: // uint64
      limit = limit_result = UINT64_MAX;
      if (negative)
        result = limit = 0;
      else
        result = (uint64_t)uint_val;
      break;

    default:
      __builtin_unreachable();
  }

  if (uint_val > limit) {
    result = limit_result;
    softfloat_raiseFlags(softfloat_flag_invalid);
  }

  SET_FS_DIRTY();
  SET_RD(insn, regs, result);
}

DECLARE_EMULATION_FUNC(emulate_fcmp)
{
  int rm = GET_RM(insn);
  if (rm >= 3)
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  uintptr_t result;
  if (GET_PRECISION(insn) == PRECISION_S) {
    uint32_t rs1 = GET_F32_RS1(insn, regs);
    uint32_t rs2 = GET_F32_RS2(insn, regs);
    if (rm != 1)
      result = f32_eq(rs1, rs2);
    if (rm == 1 || (rm == 0 && !result))
      result = f32_lt(rs1, rs2);
    goto success;
  } else if (GET_PRECISION(insn) == PRECISION_D) {
    uint64_t rs1 = GET_F64_RS1(insn, regs);
    uint64_t rs2 = GET_F64_RS2(insn, regs);
    if (rm != 1)
      result = f64_eq(rs1, rs2);
    if (rm == 1 || (rm == 0 && !result))
      result = f64_lt(rs1, rs2);
    goto success;
  }
  return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
success:
  SET_FS_DIRTY();
  SET_RD(insn, regs, result);
}

DECLARE_EMULATION_FUNC(emulate_fmv_if)
{
  uintptr_t result;
  if ((insn >> 20) & 0x1f)
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  if (GET_PRECISION(insn) == PRECISION_S) {
    result = GET_F32_RS1(insn, regs);
    switch (GET_RM(insn)) {
      case GET_RM(MATCH_FMV_X_W): break;
      case GET_RM(MATCH_FCLASS_S): result = f32_classify(result); break;
      default: return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
    }
  } else if (GET_PRECISION(insn) == PRECISION_D) {
    result = GET_F64_RS1(insn, regs);
    switch (GET_RM(insn)) {
      case GET_RM(MATCH_FMV_X_D): break;
      case GET_RM(MATCH_FCLASS_D): result = f64_classify(result); break;
      default: return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
    }
  } else {
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
  }

  SET_FS_DIRTY();
  SET_RD(insn, regs, result);
}

DECLARE_EMULATION_FUNC(emulate_fmv_fi)
{
  uintptr_t rs1 = GET_RS1(insn, regs);

  if ((insn & MASK_FMV_W_X) == MATCH_FMV_W_X)
    SET_F32_RD(insn, regs, rs1);
#if __riscv_xlen == 64
  else if ((insn & MASK_FMV_D_X) == MATCH_FMV_D_X)
    SET_F64_RD(insn, regs, rs1);
#endif
  else
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
}

DECLARE_EMULATION_FUNC(emulate_fmadd)
{
  // if FPU is disabled, punt back to the OS
  if (unlikely((mstatus & MSTATUS_FS) == 0))
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);

  int op = (insn >> 2) & 3;
  SETUP_STATIC_ROUNDING(insn);
  if (GET_PRECISION(insn) == PRECISION_S) {
    uint32_t rs1 = GET_F32_RS1(insn, regs);
    uint32_t rs2 = GET_F32_RS2(insn, regs);
    uint32_t rs3 = GET_F32_RS3(insn, regs);
    SET_F32_RD(insn, regs, softfloat_mulAddF32(op, rs1, rs2, rs3));
  } else if (GET_PRECISION(insn) == PRECISION_D) {
    uint64_t rs1 = GET_F64_RS1(insn, regs);
    uint64_t rs2 = GET_F64_RS2(insn, regs);
    uint64_t rs3 = GET_F64_RS3(insn, regs);
    SET_F64_RD(insn, regs, softfloat_mulAddF64(op, rs1, rs2, rs3));
  } else {
    return truly_illegal_insn(regs, mcause, mepc, mstatus, insn);
  }
}
