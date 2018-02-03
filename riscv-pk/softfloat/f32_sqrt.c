
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

float32_t f32_sqrt( float32_t a )
{
    union ui32_f32 uA;
    uint_fast32_t uiA;
    bool signA;
    int_fast16_t expA;
    uint_fast32_t sigA, uiZ;
    struct exp16_sig32 normExpSig;
    int_fast16_t expZ;
    uint_fast32_t sigZ;
    uint_fast64_t term, rem;
    union ui32_f32 uZ;

    uA.f = a;
    uiA = uA.ui;
    signA = signF32UI( uiA );
    expA = expF32UI( uiA );
    sigA = fracF32UI( uiA );
    if ( expA == 0xFF ) {
        if ( sigA ) {
            uiZ = softfloat_propagateNaNF32UI( uiA, 0 );
            goto uiZ;
        }
        if ( ! signA ) return a;
        goto invalid;
    }
    if ( signA ) {
        if ( ! ( expA | sigA ) ) return a;
        goto invalid;
    }
    if ( ! expA ) {
        if ( ! sigA ) return a;
        normExpSig = softfloat_normSubnormalF32Sig( sigA );
        expA = normExpSig.exp;
        sigA = normExpSig.sig;
    }
    expZ = ( ( expA - 0x7F )>>1 ) + 0x7E;
    sigA = ( sigA | 0x00800000 )<<8;
    sigZ = softfloat_estimateSqrt32( expA, sigA ) + 2;
    if ( ( sigZ & 0x7F ) <= 5 ) {
        if ( sigZ < 2 ) {
            sigZ = 0x7FFFFFFF;
            goto roundPack;
        }
        sigA >>= expA & 1;
        term = (uint_fast64_t) sigZ * sigZ;
        rem = ( (uint_fast64_t) sigA<<32 ) - term;
        while ( UINT64_C( 0x8000000000000000 ) <= rem ) {
            --sigZ;
            rem += ( (uint_fast64_t) sigZ<<1 ) | 1;
        }
        sigZ |= ( rem != 0 );
    }
    sigZ = softfloat_shortShift32Right1Jam( sigZ );
 roundPack:
    return softfloat_roundPackToF32( 0, expZ, sigZ );
 invalid:
    softfloat_raiseFlags( softfloat_flag_invalid );
    uiZ = defaultNaNF32UI;
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

