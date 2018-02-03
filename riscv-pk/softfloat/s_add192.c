
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

struct uint192
 softfloat_add192(
     uint64_t a128,
     uint64_t a64,
     uint64_t a0,
     uint64_t b128,
     uint64_t b64,
     uint64_t b0
 )
{
    struct uint192 z;
    unsigned int carry64, carry128;

    z.v0 = a0 + b0;
    carry64 = ( z.v0 < a0 );
    z.v64 = a64 + b64;
    carry128 = ( z.v64 < a64 );
    z.v128 = a128 + b128;
    z.v64 += carry64;
    carry128 += ( z.v64 < carry64 );
    z.v128 += carry128;
    return z;

}

