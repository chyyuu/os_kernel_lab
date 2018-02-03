
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "softfloat.h"

float64_t
 softfloat_roundPackToF64( bool sign, int_fast16_t exp, uint_fast64_t sig )
{
    int roundingMode;
    bool roundNearestEven;
    int roundIncrement, roundBits;
    bool isTiny;
    uint_fast64_t uiZ;
    union ui64_f64 uZ;

    roundingMode = softfloat_roundingMode;
    roundNearestEven = ( roundingMode == softfloat_round_nearest_even );
    roundIncrement = 0x200;
    if (
           ! roundNearestEven
        && ( roundingMode != softfloat_round_nearest_maxMag )
    ) {
        roundIncrement =
               ( roundingMode == softfloat_round_minMag )
            || ( roundingMode
                     == ( sign ? softfloat_round_max : softfloat_round_min ) )
                ? 0
                : 0x3FF;
    }
    roundBits = sig & 0x3FF;
    if ( 0x7FD <= (uint16_t) exp ) {
        if ( exp < 0 ) {
            isTiny =
                   ( softfloat_detectTininess
                         == softfloat_tininess_beforeRounding )
                || ( exp < -1 )
                || ( sig + roundIncrement < UINT64_C( 0x8000000000000000 ) );
            sig = softfloat_shift64RightJam( sig, - exp );
            exp = 0;
            roundBits = sig & 0x3FF;
            if ( isTiny && roundBits ) {
                softfloat_raiseFlags( softfloat_flag_underflow );
            }
        } else if (
            ( 0x7FD < exp )
                || ( UINT64_C( 0x8000000000000000 ) <= sig + roundIncrement )
        ) {
            softfloat_raiseFlags(
                softfloat_flag_overflow | softfloat_flag_inexact );
            uiZ = packToF64UI( sign, 0x7FF, 0 ) - ! roundIncrement;
            goto uiZ;
        }
    }
    if ( roundBits ) softfloat_raiseFlags( softfloat_flag_inexact );
    sig = ( sig + roundIncrement )>>10;
    sig &= ~ ( ! ( roundBits ^ 0x200 ) & roundNearestEven );
    uiZ = packToF64UI( sign, sig ? exp : 0, sig );
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

