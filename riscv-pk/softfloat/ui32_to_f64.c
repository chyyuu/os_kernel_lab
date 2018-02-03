
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "softfloat.h"

float64_t ui32_to_f64( uint_fast32_t a )
{
    uint_fast64_t uiZ;
    int shiftCount;
    union ui64_f64 uZ;

    if ( ! a ) {
        uiZ = 0;
    } else {
        shiftCount = softfloat_countLeadingZeros32( a ) + 21;
        uiZ =
            packToF64UI(
                0, 0x432 - shiftCount, (uint_fast64_t) a<<shiftCount );
    }
    uZ.ui = uiZ;
    return uZ.f;

}

