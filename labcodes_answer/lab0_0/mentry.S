// See LICENSE for license details.

#include "mtrap.h"
#include "bits.h"

  .section .text.init,"ax",@progbits
  .globl reset_vector
reset_vector:
  j do_reset

#define HTIF_TOHOST   0x40008000

putstrings:
  li a2, HTIF_TOHOST
  li a3, (1 << 24) | (1 << 16)
1:      
  lbu a1, (a0)
  beqz a1, 2f
/* Note: we use 32 bit accesses to work in all base isa modes */
  sw a1, 0(a2)
  sw a3, 4(a2)
/* wait until the char is handled */
3:      
  lw a1, 0(a2)
  lw a4, 4(a2)
  or a1, a1, a4
  bnez a1, 3b
  addi a0, a0, 1
  j 1b
2:
  ret
fatal_error:
  jal putstrings
  # exit the emulator if possible
  li a2, HTIF_TOHOST
  li a1, 1
  sw a1, 0(a2)
  sw zero, 4(a2)
1:  
  wfi
  j 1b

rv32_expected_str:
  .asciz "Must run this program on a 32 bit RISCV CPU - aborting\n"
  .align 2
rv64_expected_str:
  .asciz "Must run this program on a 64 bit RISCV CPU - aborting\n"
rv128_detected_str:
  .asciz "128 bit RISCV CPU detected: setting XLEN to 64 bits\n"
  .align 4  /*chyyuu do_reset should be aligned 4 bytes. */


do_reset:
  li x1, 0
  li x2, 0
  li x3, 0
  li x4, 0
  li x5, 0
  li x6, 0
  li x7, 0
  li x8, 0
  li x9, 0
// save a0 and a1; arguments from previous boot loader stage:
//  li x10, 0
//  li x11, 0
  li x12, 0
  li x13, 0
  li x14, 0
  li x15, 0
  li x16, 0
  li x17, 0
  li x18, 0
  li x19, 0
  li x20, 0
  li x21, 0
  li x22, 0
  li x23, 0
  li x24, 0
  li x25, 0
  li x26, 0
  li x27, 0
  li x28, 0
  li x29, 0
  li x30, 0
  li x31, 0
  csrw mscratch, x0

  # check MXL value and abort if it is not what we expect
  mv s0, a0
  mv s1, a1
  csrr a0, misa
  bgez a0, misa_rv32
#if __riscv_xlen == 32
  la a0, rv32_expected_str
  j fatal_error
#else
  slli a0, a0, 1
  bgez a0, misa_ok
  # we are on a 128 bit CPU: we force MXL to 64 bit as a test
  la a0, rv128_detected_str
  jal putstrings
  li a0, 1
  li a1, 126
  # cannot use slli because no 128 bit support in gas
  sll a0, a0, a1 
  csrc misa, a0
  # also set MSTATUS.SXL and MSTATUS.UXL to 64 bits
  li a0, (3 << 32) | (3 << 34)
  csrs mstatus, a0
  li a0, (1 << 32) | (1 << 34)
  csrc mstatus, a0
  j misa_ok
#endif    
misa_rv32:
#if __riscv_xlen == 64
  la a0, rv64_expected_str
  j fatal_error
#endif
misa_ok:
  mv a0, s0
  mv a1, s1

  la sp, stacks + RISCV_PGSIZE - MENTRY_FRAME_SIZE

  csrr a3, mhartid
  slli a2, a3, RISCV_PGSHIFT
  add sp, sp, a2

  # Boot on the first hart
  beqz a3, boot_loader

  .bss
  .align RISCV_PGSHIFT
stacks:
  .skip RISCV_PGSIZE * MAX_HARTS
