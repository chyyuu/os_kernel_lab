
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

float64_t f64_sqrt( float64_t a )
{
    union ui64_f64 uA;
    uint_fast64_t uiA;
    bool signA;
    int_fast16_t expA;
    uint_fast64_t sigA, uiZ;
    struct exp16_sig64 normExpSig;
    int_fast16_t expZ;
    uint_fast32_t sigZ32;
    uint_fast64_t sigZ;
    struct uint128 term, rem;
    union ui64_f64 uZ;

    uA.f = a;
    uiA = uA.ui;
    signA = signF64UI( uiA );
    expA = expF64UI( uiA );
    sigA = fracF64UI( uiA );
    if ( expA == 0x7FF ) {
        if ( sigA ) {
            uiZ = softfloat_propagateNaNF64UI( uiA, 0 );
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
        normExpSig = softfloat_normSubnormalF64Sig( sigA );
        expA = normExpSig.exp;
        sigA = normExpSig.sig;
    }
    expZ = ( ( expA - 0x3FF )>>1 ) + 0x3FE;
    sigA |= UINT64_C( 0x0010000000000000 );
    sigZ32 = softfloat_estimateSqrt32( expA, sigA>>21 );
    sigA <<= 9 - ( expA & 1 );
    sigZ =
        softfloat_estimateDiv128To64( sigA, 0, (uint_fast64_t) sigZ32<<32 )
            + ( (uint_fast64_t) sigZ32<<30 );
    if ( ( sigZ & 0x1FF ) <= 5 ) {
        term = softfloat_mul64To128( sigZ, sigZ );
        rem = softfloat_sub128( sigA, 0, term.v64, term.v0 );
        while ( UINT64_C( 0x8000000000000000 ) <= rem.v64 ) {
            --sigZ;
            rem =
                softfloat_add128(
                    rem.v64, rem.v0, sigZ>>63, (uint64_t) ( sigZ<<1 ) );
        }
        sigZ |= ( ( rem.v64 | rem.v0 ) != 0 );
    }
    return softfloat_roundPackToF64( 0, expZ, sigZ );
 invalid:
    softfloat_raiseFlags( softfloat_flag_invalid );
    uiZ = defaultNaNF64UI;
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

