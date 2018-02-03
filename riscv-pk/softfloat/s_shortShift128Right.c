
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

struct uint128
 softfloat_shortShift128Right( uint64_t a64, uint64_t a0, unsigned int count )
{
    struct uint128 z;

    z.v64 = a64>>count;
    z.v0 = a64<<( ( - count ) & 63 ) | a0>>count;
    return z;

}

