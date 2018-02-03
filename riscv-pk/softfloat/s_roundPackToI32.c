
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

int_fast32_t
 softfloat_roundPackToI32(
     bool sign, uint_fast64_t sig, int_fast8_t roundingMode, bool exact )
{
    bool roundNearestEven;
    int roundIncrement, roundBits;
    uint_fast32_t sig32;
    union { uint32_t ui; int32_t i; } uZ;
    int_fast32_t z;

    roundNearestEven = ( roundingMode == softfloat_round_nearest_even );
    roundIncrement = 0x40;
    if (
           ! roundNearestEven
        && ( roundingMode != softfloat_round_nearest_maxMag )
    ) {
        roundIncrement =
               ( roundingMode == softfloat_round_minMag )
            || ( roundingMode
                     == ( sign ? softfloat_round_max : softfloat_round_min ) )
                ? 0
                : 0x7F;
    }
    roundBits = sig & 0x7F;
    sig += roundIncrement;
    if ( sig & UINT64_C( 0xFFFFFF8000000000 ) ) goto invalid;
    sig32 = sig>>7;
    sig32 &= ~ ( ! ( roundBits ^ 0x40 ) & roundNearestEven );
    uZ.ui = sign ? - sig32 : sig32;
    z = uZ.i;
    if ( z && ( ( z < 0 ) ^ sign ) ) goto invalid;
    if ( exact && roundBits ) {
        softfloat_raiseFlags( softfloat_flag_inexact );
    }
    return z;
 invalid:
    softfloat_raiseFlags( softfloat_flag_invalid );
    return sign ? -0x7FFFFFFF - 1 : 0x7FFFFFFF;

}

