
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

float32_t f32_div( float32_t a, float32_t b )
{
    union ui32_f32 uA;
    uint_fast32_t uiA;
    bool signA;
    int_fast16_t expA;
    uint_fast32_t sigA;
    union ui32_f32 uB;
    uint_fast32_t uiB;
    bool signB;
    int_fast16_t expB;
    uint_fast32_t sigB;
    bool signZ;
    struct exp16_sig32 normExpSig;
    int_fast16_t expZ;
    uint_fast32_t sigZ;
    uint_fast32_t uiZ;
    union ui32_f32 uZ;

    uA.f = a;
    uiA = uA.ui;
    signA = signF32UI( uiA );
    expA = expF32UI( uiA );
    sigA = fracF32UI( uiA );
    uB.f = b;
    uiB = uB.ui;
    signB = signF32UI( uiB );
    expB = expF32UI( uiB );
    sigB = fracF32UI( uiB );
    signZ = signA ^ signB;
    if ( expA == 0xFF ) {
        if ( sigA ) goto propagateNaN;
        if ( expB == 0xFF ) {
            if ( sigB ) goto propagateNaN;
            goto invalid;
        }
        goto infinity;
    }
    if ( expB == 0xFF ) {
        if ( sigB ) goto propagateNaN;
        goto zero;
    }
    if ( ! expB ) {
        if ( ! sigB ) {
            if ( ! ( expA | sigA ) ) goto invalid;
            softfloat_raiseFlags( softfloat_flag_infinity );
            goto infinity;
        }
        normExpSig = softfloat_normSubnormalF32Sig( sigB );
        expB = normExpSig.exp;
        sigB = normExpSig.sig;
    }
    if ( ! expA ) {
        if ( ! sigA ) goto zero;
        normExpSig = softfloat_normSubnormalF32Sig( sigA );
        expA = normExpSig.exp;
        sigA = normExpSig.sig;
    }
    expZ = expA - expB + 0x7D;
    sigA = ( sigA | 0x00800000 )<<7;
    sigB = ( sigB | 0x00800000 )<<8;
    if ( sigB <= ( sigA + sigA ) ) {
        ++expZ;
        sigA >>= 1;
    }
    sigZ = ( (uint_fast64_t) sigA<<32 ) / sigB;
    if ( ! ( sigZ & 0x3F ) ) {
        sigZ |= ( (uint_fast64_t) sigB * sigZ != (uint_fast64_t) sigA<<32 );
    }
    return softfloat_roundPackToF32( signZ, expZ, sigZ );
 propagateNaN:
    uiZ = softfloat_propagateNaNF32UI( uiA, uiB );
    goto uiZ;
 invalid:
    softfloat_raiseFlags( softfloat_flag_invalid );
    uiZ = defaultNaNF32UI;
    goto uiZ;
 infinity:
    uiZ = packToF32UI( signZ, 0xFF, 0 );
    goto uiZ;
 zero:
    uiZ = packToF32UI( signZ, 0, 0 );
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

