
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

float64_t f64_div( float64_t a, float64_t b )
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
    struct exp16_sig64 normExpSig;
    int_fast16_t expZ;
    uint_fast64_t sigZ;
    struct uint128 term, rem;
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
    signZ = signA ^ signB;
    if ( expA == 0x7FF ) {
        if ( sigA ) goto propagateNaN;
        if ( expB == 0x7FF ) {
            if ( sigB ) goto propagateNaN;
            goto invalid;
        }
        goto infinity;
    }
    if ( expB == 0x7FF ) {
        if ( sigB ) goto propagateNaN;
        goto zero;
    }
    if ( ! expB ) {
        if ( ! sigB ) {
            if ( ! ( expA | sigA ) ) goto invalid;
            softfloat_raiseFlags( softfloat_flag_infinity );
            goto infinity;
        }
        normExpSig = softfloat_normSubnormalF64Sig( sigB );
        expB = normExpSig.exp;
        sigB = normExpSig.sig;
    }
    if ( ! expA ) {
        if ( ! sigA ) goto zero;
        normExpSig = softfloat_normSubnormalF64Sig( sigA );
        expA = normExpSig.exp;
        sigA = normExpSig.sig;
    }
    expZ = expA - expB + 0x3FD;
    sigA = ( sigA | UINT64_C( 0x0010000000000000 ) )<<10;
    sigB = ( sigB | UINT64_C( 0x0010000000000000 ) )<<11;
    if ( sigB <= ( sigA + sigA ) ) {
        ++expZ;
        sigA >>= 1;
    }
    sigZ = softfloat_estimateDiv128To64( sigA, 0, sigB );
    if ( ( sigZ & 0x1FF ) <= 2 ) {
        term = softfloat_mul64To128( sigB, sigZ );
        rem = softfloat_sub128( sigA, 0, term.v64, term.v0 );
        while ( UINT64_C( 0x8000000000000000 ) <= rem.v64 ) {
            --sigZ;
            rem = softfloat_add128( rem.v64, rem.v0, 0, sigB );
        }
        sigZ |= ( rem.v0 != 0 );
    }
    return softfloat_roundPackToF64( signZ, expZ, sigZ );
 propagateNaN:
    uiZ = softfloat_propagateNaNF64UI( uiA, uiB );
    goto uiZ;
 invalid:
    softfloat_raiseFlags( softfloat_flag_invalid );
    uiZ = defaultNaNF64UI;
    goto uiZ;
 infinity:
    uiZ = packToF64UI( signZ, 0x7FF, 0 );
    goto uiZ;
 zero:
    uiZ = packToF64UI( signZ, 0, 0 );
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

