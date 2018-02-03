
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

float64_t f64_roundToInt( float64_t a, int_fast8_t roundingMode, bool exact )
{
    union ui64_f64 uA;
    uint_fast64_t uiA;
    int_fast16_t expA;
    uint_fast64_t uiZ;
    bool signA;
    uint_fast64_t lastBitMask, roundBitsMask;
    union ui64_f64 uZ;

    uA.f = a;
    uiA = uA.ui;
    expA = expF64UI( uiA );
    if ( 0x433 <= expA ) {
        if ( ( expA == 0x7FF ) && fracF64UI( uiA ) ) {
            uiZ = softfloat_propagateNaNF64UI( uiA, 0 );
            goto uiZ;
        }
        return a;
    }
    if ( expA <= 0x3FE ) {
        if ( ! ( uiA & UINT64_C( 0x7FFFFFFFFFFFFFFF ) ) ) return a;
        if ( exact ) softfloat_raiseFlags( softfloat_flag_inexact );
        signA = signF64UI( uiA );
        switch ( roundingMode ) {
         case softfloat_round_nearest_even:
            if ( ( expA == 0x3FE ) && fracF64UI( uiA ) ) {
                uiZ = packToF64UI( signA, 0x3FF, 0 );
                goto uiZ;
            }
            break;
         case softfloat_round_min:
            uiZ = signA ? UINT64_C( 0xBFF0000000000000 ) : 0;
            goto uiZ;
         case softfloat_round_max:
            uiZ =
                signA ? UINT64_C( 0x8000000000000000 )
                    : UINT64_C( 0x3FF0000000000000 );
            goto uiZ;
         case softfloat_round_nearest_maxMag:
            if ( expA == 0x3FE ) {
                uiZ = packToF64UI( signA, 0x3FF, 0 );
                goto uiZ;
            }
            break;
        }
        uiZ = packToF64UI( signA, 0, 0 );
        goto uiZ;
    }
    lastBitMask = (uint_fast64_t) 1<<( 0x433 - expA );
    roundBitsMask = lastBitMask - 1;
    uiZ = uiA;
    if ( roundingMode == softfloat_round_nearest_maxMag ) {
        uiZ += lastBitMask>>1;
    } else if ( roundingMode == softfloat_round_nearest_even ) {
        uiZ += lastBitMask>>1;
        if ( ! ( uiZ & roundBitsMask ) ) uiZ &= ~ lastBitMask;
    } else if ( roundingMode != softfloat_round_minMag ) {
        if ( signF64UI( uiZ ) ^ ( roundingMode == softfloat_round_max ) ) {
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

