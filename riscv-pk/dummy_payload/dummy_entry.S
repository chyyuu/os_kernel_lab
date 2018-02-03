#include "mcall.h"

  .section ".text.init"
  .globl _start
_start:
  la s0, str
1:
  lbu a0, (s0)
  beqz a0, 1f
  li a7, SBI_CONSOLE_PUTCHAR
  ecall
  add s0, s0, 1
  j 1b

1:
  li a7, SBI_SHUTDOWN
  ecall

  .data
str:
  .asciz "This is bbl's dummy_payload.  To boot a real kernel, reconfigure\n\
bbl with the flag --with-payload=PATH, then rebuild bbl.\n"
