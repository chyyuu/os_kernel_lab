
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"

struct exp16_sig32 softfloat_normSubnormalF32Sig( uint_fast32_t sig )
{
    int shiftCount;
    struct exp16_sig32 z;

    shiftCount = softfloat_countLeadingZeros32( sig ) - 8;
    z.exp = 1 - shiftCount;
    z.sig = sig<<shiftCount;
    return z;

}

