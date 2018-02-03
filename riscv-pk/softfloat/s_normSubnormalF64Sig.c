
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"

struct exp16_sig64 softfloat_normSubnormalF64Sig( uint_fast64_t sig )
{
    int shiftCount;
    struct exp16_sig64 z;

    shiftCount = softfloat_countLeadingZeros64( sig ) - 11;
    z.exp = 1 - shiftCount;
    z.sig = sig<<shiftCount;
    return z;

}

