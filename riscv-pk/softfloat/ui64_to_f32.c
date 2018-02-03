
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "softfloat.h"

float32_t ui64_to_f32( uint_fast64_t a )
{
    int shiftCount;
    union ui32_f32 u;
    uint_fast32_t sig;

    shiftCount = softfloat_countLeadingZeros64( a ) - 40;
    if ( 0 <= shiftCount ) {
        u.ui =
            a ? packToF32UI(
                    0, 0x95 - shiftCount, (uint_fast32_t) a<<shiftCount )
                : 0;
        return u.f;
    } else {
        shiftCount += 7;
        sig =
            ( shiftCount < 0 )
                ? softfloat_shortShift64RightJam( a, - shiftCount )
                : (uint_fast32_t) a<<shiftCount;
        return softfloat_roundPackToF32( 0, 0x9C - shiftCount, sig );
    }

}

