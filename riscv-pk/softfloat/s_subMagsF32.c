
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

float32_t
 softfloat_subMagsF32( uint_fast32_t uiA, uint_fast32_t uiB, bool signZ )
{
    int_fast16_t expA;
    uint_fast32_t sigA;
    int_fast16_t expB;
    uint_fast32_t sigB;
    int_fast16_t expDiff;
    uint_fast32_t uiZ;
    int_fast16_t expZ;
    uint_fast32_t sigZ;
    union ui32_f32 uZ;

    expA = expF32UI( uiA );
    sigA = fracF32UI( uiA );
    expB = expF32UI( uiB );
    sigB = fracF32UI( uiB );
    expDiff = expA - expB;
    sigA <<= 7;
    sigB <<= 7;
    if ( 0 < expDiff ) goto expABigger;
    if ( expDiff < 0 ) goto expBBigger;
    if ( expA == 0xFF ) {
        if ( sigA | sigB ) goto propagateNaN;
        softfloat_raiseFlags( softfloat_flag_invalid );
        uiZ = defaultNaNF32UI;
        goto uiZ;
    }
    if ( ! expA ) {
        expA = 1;
        expB = 1;
    }
    if ( sigB < sigA ) goto aBigger;
    if ( sigA < sigB ) goto bBigger;
    uiZ = packToF32UI( softfloat_roundingMode == softfloat_round_min, 0, 0 );
    goto uiZ;
 expBBigger:
    if ( expB == 0xFF ) {
        if ( sigB ) goto propagateNaN;
        uiZ = packToF32UI( signZ ^ 1, 0xFF, 0 );
        goto uiZ;
    }
    sigA += expA ? 0x40000000 : sigA;
    sigA = softfloat_shift32RightJam( sigA, - expDiff );
    sigB |= 0x40000000;
 bBigger:
    signZ ^= 1;
    expZ = expB;
    sigZ = sigB - sigA;
    goto normRoundPack;
 expABigger:
    if ( expA == 0xFF ) {
        if ( sigA ) goto propagateNaN;
        uiZ = uiA;
        goto uiZ;
    }
    sigB += expB ? 0x40000000 : sigB;
    sigB = softfloat_shift32RightJam( sigB, expDiff );
    sigA |= 0x40000000;
 aBigger:
    expZ = expA;
    sigZ = sigA - sigB;
 normRoundPack:
    return softfloat_normRoundPackToF32( signZ, expZ - 1, sigZ );
 propagateNaN:
    uiZ = softfloat_propagateNaNF32UI( uiA, uiB );
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

