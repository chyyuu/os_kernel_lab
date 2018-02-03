
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

struct uint192
 softfloat_mul128By64To192( uint64_t a64, uint64_t a0, uint64_t b )
{
    struct uint128 p0, p64;
    struct uint192 z;

    p0 = softfloat_mul64To128( a0, b );
    z.v0 = p0.v0;
    p64 = softfloat_mul64To128( a64, b );
    z.v64 = p64.v0 + p0.v64;
    z.v128 = p64.v64 + ( z.v64 < p64.v0 );
    return z;

}

