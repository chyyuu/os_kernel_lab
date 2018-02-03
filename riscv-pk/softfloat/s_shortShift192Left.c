
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

struct uint192
 softfloat_shortShift192Left(
     uint64_t a128, uint64_t a64, uint64_t a0, unsigned int count )
{
    unsigned int negCount;
    struct uint192 z;

    negCount = - count;
    z.v128 = a128<<count | a64>>( negCount & 63 );
    z.v64 = a64<<count | a0>>( negCount & 63 );
    z.v0 = a0<<count;
    return z;

}

