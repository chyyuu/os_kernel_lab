#include "encoding.h"

  .section .rodata
  .globl logo
logo:
  .incbin BBL_LOGO_FILE
  .byte 0
