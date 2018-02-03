
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

struct uint192
 softfloat_sub192(
     uint64_t a128,
     uint64_t a64,
     uint64_t a0,
     uint64_t b128,
     uint64_t b64,
     uint64_t b0
 )
{
    struct uint192 z;
    unsigned int borrow64, borrow128;

    z.v0 = a0 - b0;
    borrow64 = ( a0 < b0 );
    z.v64 = a64 - b64;
    borrow128 = ( a64 < b64 );
    z.v128 = a128 - b128;
    borrow128 += ( z.v64 < borrow64 );
    z.v64 -= borrow64;
    z.v128 -= borrow128;
    return z;

}

