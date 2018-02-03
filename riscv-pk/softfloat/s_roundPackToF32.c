
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "softfloat.h"

float32_t
 softfloat_roundPackToF32( bool sign, int_fast16_t exp, uint_fast32_t sig )
{
    int roundingMode;
    bool roundNearestEven;
    int roundIncrement, roundBits;
    bool isTiny;
    uint_fast32_t uiZ;
    union ui32_f32 uZ;

    roundingMode = softfloat_roundingMode;
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
    if ( 0xFD <= (uint16_t) exp ) {
        if ( exp < 0 ) {
            isTiny =
                   ( softfloat_detectTininess
                         == softfloat_tininess_beforeRounding )
                || ( exp < -1 )
                || ( sig + roundIncrement < 0x80000000 );
            sig = softfloat_shift32RightJam( sig, - exp );
            exp = 0;
            roundBits = sig & 0x7F;
            if ( isTiny && roundBits ) {
                softfloat_raiseFlags( softfloat_flag_underflow );
            }
        } else if (
            ( 0xFD < exp ) || ( 0x80000000 <= sig + roundIncrement )
        ) {
            softfloat_raiseFlags(
                softfloat_flag_overflow | softfloat_flag_inexact );
            uiZ = packToF32UI( sign, 0xFF, 0 ) - ! roundIncrement;
            goto uiZ;
        }
    }
    if ( roundBits ) softfloat_raiseFlags( softfloat_flag_inexact );
    sig = ( sig + roundIncrement )>>7;
    sig &= ~ ( ! ( roundBits ^ 0x40 ) & roundNearestEven );
    uiZ = packToF32UI( sign, sig ? exp : 0, sig );
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

