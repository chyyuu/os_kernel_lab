
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

struct uint128 softfloat_mul64To128( uint64_t a, uint64_t b )
{
    uint32_t a32, a0, b32, b0;
    struct uint128 z;
    uint64_t mid1, mid2, mid;

    a32 = a>>32;
    a0 = a;
    b32 = b>>32;
    b0 = b;
    z.v0 = (uint64_t) a0 * b0;
    mid1 = (uint64_t) a32 * b0;
    mid2 = (uint64_t) a0 * b32;
    z.v64 = (uint64_t) a32 * b32;
    mid = mid1 + mid2;
    z.v64 += ( (uint64_t) ( mid < mid1 ) )<<32 | mid>>32;
    mid <<= 32;
    z.v0 += mid;
    z.v64 += ( z.v0 < mid );
    return z;

}

