
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

struct uint256
 softfloat_mul128To256( uint64_t a64, uint64_t a0, uint64_t b64, uint64_t b0 )
{
    struct uint128 p0, p64, p128;
    struct uint256 z;

    p0 = softfloat_mul64To128( a0, b0 );
    z.v0 = p0.v0;
    p64 = softfloat_mul64To128( a64, b0 );
    z.v64 = p64.v0 + p0.v64;
    z.v128 = p64.v64 + ( z.v64 < p64.v0 );
    p128 = softfloat_mul64To128( a64, b64 );
    z.v128 += p128.v0;
    z.v192 = p128.v64 + ( z.v128 < p128.v0 );
    p64 = softfloat_mul64To128( a0, b64 );
    z.v64 += p64.v0;
    p64.v64 += ( z.v64 < p64.v0 );
    z.v128 += p64.v64;
    z.v192 += ( z.v128 < p64.v64 );
    return z;

}

