
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

float64_t f64_rem( float64_t a, float64_t b )
{
    union ui64_f64 uA;
    uint_fast64_t uiA;
    bool signA;
    int_fast16_t expA;
    uint_fast64_t sigA;
    union ui64_f64 uB;
    uint_fast64_t uiB;
    bool signB;
    int_fast16_t expB;
    uint_fast64_t sigB;
    struct exp16_sig64 normExpSig;
    int_fast16_t expDiff;
    uint_fast64_t q, alternateSigA;
    uint64_t sigMean;
    bool signZ;
    uint_fast64_t uiZ;
    union ui64_f64 uZ;

    uA.f = a;
    uiA = uA.ui;
    signA = signF64UI( uiA );
    expA = expF64UI( uiA );
    sigA = fracF64UI( uiA );
    uB.f = b;
    uiB = uB.ui;
    signB = signF64UI( uiB );
    expB = expF64UI( uiB );
    sigB = fracF64UI( uiB );
    if ( expA == 0x7FF ) {
        if ( sigA || ( ( expB == 0x7FF ) && sigB ) ) goto propagateNaN;
        goto invalid;
    }
    if ( expB == 0x7FF ) {
        if ( sigB ) goto propagateNaN;
        return a;
    }
    if ( ! expB ) {
        if ( ! sigB ) goto invalid;
        normExpSig = softfloat_normSubnormalF64Sig( sigB );
        expB = normExpSig.exp;
        sigB = normExpSig.sig;
    }
    if ( ! expA ) {
        if ( ! sigA ) return a;
        normExpSig = softfloat_normSubnormalF64Sig( sigA );
        expA = normExpSig.exp;
        sigA = normExpSig.sig;
    }
    expDiff = expA - expB;
    sigA = ( sigA | UINT64_C( 0x0010000000000000 ) )<<11;
    sigB = ( sigB | UINT64_C( 0x0010000000000000 ) )<<11;
    if ( expDiff < 0 ) {
        if ( expDiff < -1 ) return a;
        sigA >>= 1;
    }
    q = ( sigB <= sigA );
    if ( q ) sigA -= sigB;
    expDiff -= 64;
    while ( 0 < expDiff ) {
        q = softfloat_estimateDiv128To64( sigA, 0, sigB );
        q = ( 2 < q ) ? q - 2 : 0;
        sigA = - ( ( sigB>>2 ) * q );
        expDiff -= 62;
    }
    expDiff += 64;
    if ( 0 < expDiff ) {
        q = softfloat_estimateDiv128To64( sigA, 0, sigB );
        q = ( 2 < q ) ? q - 2 : 0;
        q >>= 64 - expDiff;
        sigB >>= 2;
        sigA = ( ( sigA>>1 )<<( expDiff - 1 ) ) - sigB * q;
    } else {
        sigA >>= 2;
        sigB >>= 2;
    }
    do {
        alternateSigA = sigA;
        ++q;
        sigA -= sigB;
    } while ( sigA < UINT64_C( 0x8000000000000000 ) );
    sigMean = sigA + alternateSigA;
    if (
        ( UINT64_C( 0x8000000000000000 ) <= sigMean )
            || ( ! sigMean && ( q & 1 ) )
    ) {
        sigA = alternateSigA;
    }
    signZ = ( UINT64_C( 0x8000000000000000 ) <= sigA );
    if ( signZ ) sigA = - sigA;
    return softfloat_normRoundPackToF64( signA ^ signZ, expB, sigA );
 propagateNaN:
    uiZ = softfloat_propagateNaNF64UI( uiA, uiB );
    goto uiZ;
 invalid:
    softfloat_raiseFlags( softfloat_flag_invalid );
    uiZ = defaultNaNF64UI;
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

