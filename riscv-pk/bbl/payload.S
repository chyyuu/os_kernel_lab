#include "encoding.h"

  .section ".payload","a",@progbits
  .align RISCV_PGSHIFT + RISCV_PGLEVEL_BITS

  .globl _payload_start, _payload_end
_payload_start:
  .incbin BBL_PAYLOAD
_payload_end:
