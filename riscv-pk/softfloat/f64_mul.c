
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

float64_t f64_mul( float64_t a, float64_t b )
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
    bool signZ;
    uint_fast64_t magBits;
    struct exp16_sig64 normExpSig;
    int_fast16_t expZ;
    struct uint128 sigZ128;
    uint_fast64_t sigZ, uiZ;
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
    signZ = signA ^ signB;
    if ( expA == 0x7FF ) {
        if ( sigA || ( ( expB == 0x7FF ) && sigB ) ) goto propagateNaN;
        magBits = expB | sigB;
        goto infArg;
    }
    if ( expB == 0x7FF ) {
        if ( sigB ) goto propagateNaN;
        magBits = expA | sigA;
        goto infArg;
    }
    if ( ! expA ) {
        if ( ! sigA ) goto zero;
        normExpSig = softfloat_normSubnormalF64Sig( sigA );
        expA = normExpSig.exp;
        sigA = normExpSig.sig;
    }
    if ( ! expB ) {
        if ( ! sigB ) goto zero;
        normExpSig = softfloat_normSubnormalF64Sig( sigB );
        expB = normExpSig.exp;
        sigB = normExpSig.sig;
    }
    expZ = expA + expB - 0x3FF;
    sigA = ( sigA | UINT64_C( 0x0010000000000000 ) )<<10;
    sigB = ( sigB | UINT64_C( 0x0010000000000000 ) )<<11;
    sigZ128 = softfloat_mul64To128( sigA, sigB );
    sigZ = sigZ128.v64 | ( sigZ128.v0 != 0 );
    if ( sigZ < UINT64_C( 0x4000000000000000 ) ) {
        --expZ;
        sigZ <<= 1;
    }
    return softfloat_roundPackToF64( signZ, expZ, sigZ );
 propagateNaN:
    uiZ = softfloat_propagateNaNF64UI( uiA, uiB );
    goto uiZ;
 infArg:
    if ( ! magBits ) {
        softfloat_raiseFlags( softfloat_flag_invalid );
        uiZ = defaultNaNF64UI;
    } else {
        uiZ = packToF64UI( signZ, 0x7FF, 0 );
    }
    goto uiZ;
 zero:
    uiZ = packToF64UI( signZ, 0, 0 );
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

