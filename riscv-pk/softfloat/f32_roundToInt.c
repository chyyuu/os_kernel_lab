
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

float32_t f32_roundToInt( float32_t a, int_fast8_t roundingMode, bool exact )
{
    union ui32_f32 uA;
    uint_fast32_t uiA;
    int_fast16_t expA;
    uint_fast32_t uiZ;
    bool signA;
    uint_fast32_t lastBitMask, roundBitsMask;
    union ui32_f32 uZ;

    uA.f = a;
    uiA = uA.ui;
    expA = expF32UI( uiA );
    if ( 0x96 <= expA ) {
        if ( ( expA == 0xFF ) && fracF32UI( uiA ) ) {
            uiZ = softfloat_propagateNaNF32UI( uiA, 0 );
            goto uiZ;
        }
        return a;
    }
    if ( expA <= 0x7E ) {
        if ( ! (uint32_t) ( uiA<<1 ) ) return a;
        if ( exact ) softfloat_raiseFlags( softfloat_flag_inexact );
        signA = signF32UI( uiA );
        switch ( roundingMode ) {
         case softfloat_round_nearest_even:
            if ( ( expA == 0x7E ) && fracF32UI( uiA ) ) {
                uiZ = packToF32UI( signA, 0x7F, 0 );
                goto uiZ;
            }
            break;
         case softfloat_round_min:
            uiZ = signA ? 0xBF800000 : 0;
            goto uiZ;
         case softfloat_round_max:
            uiZ = signA ? 0x80000000 : 0x3F800000;
            goto uiZ;
         case softfloat_round_nearest_maxMag:
            if ( expA == 0x7E ) {
                uiZ = packToF32UI( signA, 0x7F, 0 );
                goto uiZ;
            }
            break;
        }
        uiZ = packToF32UI( signA, 0, 0 );
        goto uiZ;
    }
    lastBitMask = (uint_fast32_t) 1<<( 0x96 - expA );
    roundBitsMask = lastBitMask - 1;
    uiZ = uiA;
    if ( roundingMode == softfloat_round_nearest_maxMag ) {
        uiZ += lastBitMask>>1;
    } else if ( roundingMode == softfloat_round_nearest_even ) {
        uiZ += lastBitMask>>1;
        if ( ! ( uiZ & roundBitsMask ) ) uiZ &= ~ lastBitMask;
    } else if ( roundingMode != softfloat_round_minMag ) {
        if ( signF32UI( uiZ ) ^ ( roundingMode == softfloat_round_max ) ) {
            uiZ += roundBitsMask;
        }
    }
    uiZ &= ~ roundBitsMask;
    if ( exact && ( uiZ != uiA ) ) {
        softfloat_raiseFlags( softfloat_flag_inexact );
    }
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

