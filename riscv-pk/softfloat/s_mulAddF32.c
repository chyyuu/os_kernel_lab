
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

float32_t
 softfloat_mulAddF32(
     int op, uint_fast32_t uiA, uint_fast32_t uiB, uint_fast32_t uiC )
{
    bool signA;
    int_fast16_t expA;
    uint_fast32_t sigA;
    bool signB;
    int_fast16_t expB;
    uint_fast32_t sigB;
    bool signC;
    int_fast16_t expC;
    uint_fast32_t sigC;
    bool signProd;
    uint_fast32_t magBits, uiZ;
    struct exp16_sig32 normExpSig;
    int_fast16_t expProd;
    uint_fast64_t sigProd;
    bool signZ;
    int_fast16_t expZ;
    uint_fast32_t sigZ;
    int_fast16_t expDiff;
    uint_fast64_t sigZ64, sigC64;
    int shiftCount;
    union ui32_f32 uZ;

    signA = signF32UI( uiA );
    expA = expF32UI( uiA );
    sigA = fracF32UI( uiA );
    signB = signF32UI( uiB );
    expB = expF32UI( uiB );
    sigB = fracF32UI( uiB );
    signC = signF32UI( uiC ) ^ ( op == softfloat_mulAdd_subC );
    expC = expF32UI( uiC );
    sigC = fracF32UI( uiC );
    signProd = signA ^ signB ^ ( op == softfloat_mulAdd_subProd );
    if ( expA == 0xFF ) {
        if ( sigA || ( ( expB == 0xFF ) && sigB ) ) goto propagateNaN_ABC;
        magBits = expB | sigB;
        goto infProdArg;
    }
    if ( expB == 0xFF ) {
        if ( sigB ) goto propagateNaN_ABC;
        magBits = expA | sigA;
        goto infProdArg;
    }
    if ( expC == 0xFF ) {
        if ( sigC ) {
            uiZ = 0;
            goto propagateNaN_ZC;
        }
        uiZ = uiC;
        goto uiZ;
    }
    if ( ! expA ) {
        if ( ! sigA ) goto zeroProd;
        normExpSig = softfloat_normSubnormalF32Sig( sigA );
        expA = normExpSig.exp;
        sigA = normExpSig.sig;
    }
    if ( ! expB ) {
        if ( ! sigB ) goto zeroProd;
        normExpSig = softfloat_normSubnormalF32Sig( sigB );
        expB = normExpSig.exp;
        sigB = normExpSig.sig;
    }
    expProd = expA + expB - 0x7E;
    sigA = ( sigA | 0x00800000 )<<7;
    sigB = ( sigB | 0x00800000 )<<7;
    sigProd = (uint_fast64_t) sigA * sigB;
    if ( sigProd < UINT64_C( 0x2000000000000000 ) ) {
        --expProd;
        sigProd <<= 1;
    }
    signZ = signProd;
    if ( ! expC ) {
        if ( ! sigC ) {
            expZ = expProd - 1;
            sigZ = softfloat_shortShift64RightJam( sigProd, 31 );
            goto roundPack;
        }
        normExpSig = softfloat_normSubnormalF32Sig( sigC );
        expC = normExpSig.exp;
        sigC = normExpSig.sig;
    }
    sigC = ( sigC | 0x00800000 )<<6;
    expDiff = expProd - expC;
    if ( signProd == signC ) {
        if ( expDiff <= 0 ) {
            expZ = expC;
            sigZ = sigC + softfloat_shift64RightJam( sigProd, 32 - expDiff );
        } else {
            expZ = expProd;
            sigZ64 =
                sigProd
                    + softfloat_shift64RightJam(
                          (uint_fast64_t) sigC<<32, expDiff );
            sigZ = softfloat_shortShift64RightJam( sigZ64, 32 );
        }
        if ( sigZ < 0x40000000 ) {
            --expZ;
            sigZ <<= 1;
        }
    } else {
/*** OPTIMIZE BETTER? ***/
        sigC64 = (uint_fast64_t) sigC<<32;
        if ( expDiff < 0 ) {
            signZ = signC;
            expZ = expC;
            sigZ64 = sigC64 - softfloat_shift64RightJam( sigProd, - expDiff );
        } else if ( ! expDiff ) {
            expZ = expProd;
            sigZ64 = sigProd - sigC64;
            if ( ! sigZ64 ) goto completeCancellation;
            if ( sigZ64 & UINT64_C( 0x8000000000000000 ) ) {
                signZ ^= 1;
                sigZ64 = - sigZ64;
            }
        } else {
            expZ = expProd;
            sigZ64 = sigProd - softfloat_shift64RightJam( sigC64, expDiff );
        }
        shiftCount = softfloat_countLeadingZeros64( sigZ64 ) - 1;
        expZ -= shiftCount;
        shiftCount -= 32;
        if ( shiftCount < 0 ) {
            sigZ = softfloat_shortShift64RightJam( sigZ64, - shiftCount );
        } else {
            sigZ = (uint_fast32_t) sigZ64<<shiftCount;
        }
    }
 roundPack:
    return softfloat_roundPackToF32( signZ, expZ, sigZ );
 propagateNaN_ABC:
    uiZ = softfloat_propagateNaNF32UI( uiA, uiB );
    goto propagateNaN_ZC;
 infProdArg:
    if ( magBits ) {
        uiZ = packToF32UI( signProd, 0xFF, 0 );
        if ( expC != 0xFF ) goto uiZ;
        if ( sigC ) goto propagateNaN_ZC;
        if ( signProd == signC ) goto uiZ;
    }
 invalid:
    softfloat_raiseFlags( softfloat_flag_invalid );
    uiZ = defaultNaNF32UI;
 propagateNaN_ZC:
    uiZ = softfloat_propagateNaNF32UI( uiZ, uiC );
    goto uiZ;
 zeroProd:
    uiZ = uiC;
    if ( ! ( expC | sigC ) && ( signProd != signC ) ) {
 completeCancellation:
        uiZ =
            packToF32UI( softfloat_roundingMode == softfloat_round_min, 0, 0 );
    }
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

