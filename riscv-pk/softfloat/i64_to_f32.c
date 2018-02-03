
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "softfloat.h"

float32_t i64_to_f32( int_fast64_t a )
{
    bool sign;
    uint_fast64_t absA;
    int shiftCount;
    union ui32_f32 u;
    uint_fast32_t sig;

    sign = ( a < 0 );
    absA = sign ? - (uint_fast64_t) a : a;
    shiftCount = softfloat_countLeadingZeros64( absA ) - 40;
    if ( 0 <= shiftCount ) {
        u.ui =
            a ? packToF32UI(
                    sign, 0x95 - shiftCount, (uint_fast32_t) absA<<shiftCount )
                : 0;
        return u.f;
    } else {
        shiftCount += 7;
        sig =
            ( shiftCount < 0 )
                ? softfloat_shortShift64RightJam( absA, - shiftCount )
                : (uint_fast32_t) absA<<shiftCount;
        return softfloat_roundPackToF32( sign, 0x9C - shiftCount, sig );
    }

}

