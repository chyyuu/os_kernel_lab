
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "softfloat.h"

float64_t i32_to_f64( int_fast32_t a )
{
    uint_fast64_t uiZ;
    bool sign;
    uint_fast32_t absA;
    int shiftCount;
    union ui64_f64 uZ;

    if ( ! a ) {
        uiZ = 0;
    } else {
        sign = ( a < 0 );
        absA = sign ? - a : a;
        shiftCount = softfloat_countLeadingZeros32( absA ) + 21;
        uiZ =
            packToF64UI(
                sign, 0x432 - shiftCount, (uint_fast64_t) absA<<shiftCount );
    }
    uZ.ui = uiZ;
    return uZ.f;

}

