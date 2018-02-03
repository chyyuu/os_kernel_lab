
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

float32_t f32_rem( float32_t a, float32_t b )
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
    struct exp16_sig32 normExpSig;
    int_fast16_t expDiff;
    uint_fast32_t q;
    uint_fast64_t sigA64, sigB64, q64;
    uint_fast32_t alternateSigA;
    uint32_t sigMean;
    bool signZ;
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
    if ( expA == 0xFF ) {
        if ( sigA || ( ( expB == 0xFF ) && sigB ) ) goto propagateNaN;
        goto invalid;
    }
    if ( expB == 0xFF ) {
        if ( sigB ) goto propagateNaN;
        return a;
    }
    if ( ! expB ) {
        if ( ! sigB ) goto invalid;
        normExpSig = softfloat_normSubnormalF32Sig( sigB );
        expB = normExpSig.exp;
        sigB = normExpSig.sig;
    }
    if ( ! expA ) {
        if ( ! sigA ) return a;
        normExpSig = softfloat_normSubnormalF32Sig( sigA );
        expA = normExpSig.exp;
        sigA = normExpSig.sig;
    }
    expDiff = expA - expB;
    sigA |= 0x00800000;
    sigB |= 0x00800000;
    if ( expDiff < 32 ) {
        sigA <<= 8;
        sigB <<= 8;
        if ( expDiff < 0 ) {
            if ( expDiff < -1 ) return a;
            sigA >>= 1;
        }
        q = ( sigB <= sigA );
        if ( q ) sigA -= sigB;
        if ( 0 < expDiff ) {
            q = ( (uint_fast64_t) sigA<<32 ) / sigB;
            q >>= 32 - expDiff;
            sigB >>= 2;
            sigA = ( ( sigA>>1 )<<( expDiff - 1 ) ) - sigB * q;
        } else {
            sigA >>= 2;
            sigB >>= 2;
        }
    } else {
        if ( sigB <= sigA ) sigA -= sigB;
        sigA64 = (uint_fast64_t) sigA<<40;
        sigB64 = (uint_fast64_t) sigB<<40;
        expDiff -= 64;
        while ( 0 < expDiff ) {
            q64 = softfloat_estimateDiv128To64( sigA64, 0, sigB64 );
            q64 = ( 2 < q64 ) ? q64 - 2 : 0;
            sigA64 = - ( ( sigB * q64 )<<38 );
            expDiff -= 62;
        }
        expDiff += 64;
        q64 = softfloat_estimateDiv128To64( sigA64, 0, sigB64 );
        q64 = ( 2 < q64 ) ? q64 - 2 : 0;
        q = q64>>( 64 - expDiff );
        sigB <<= 6;
        sigA = ( ( sigA64>>33 )<<( expDiff - 1 ) ) - sigB * q;
    }
    do {
        alternateSigA = sigA;
        ++q;
        sigA -= sigB;
    } while ( sigA < 0x80000000 );
    sigMean = sigA + alternateSigA;
    if ( ( 0x80000000 <= sigMean ) || ( ! sigMean && ( q & 1 ) ) ) {
        sigA = alternateSigA;
    }
    signZ = ( 0x80000000 <= sigA );
    if ( signZ ) sigA = - sigA;
    return softfloat_normRoundPackToF32( signA ^ signZ, expB, sigA );
 propagateNaN:
    uiZ = softfloat_propagateNaNF32UI( uiA, uiB );
    goto uiZ;
 invalid:
    softfloat_raiseFlags( softfloat_flag_invalid );
    uiZ = defaultNaNF32UI;
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

