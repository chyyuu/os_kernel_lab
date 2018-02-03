
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "primitives.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

float64_t
 softfloat_mulAddF64(
     int op, uint_fast64_t uiA, uint_fast64_t uiB, uint_fast64_t uiC )
{
    bool signA;
    int_fast16_t expA;
    uint_fast64_t sigA;
    bool signB;
    int_fast16_t expB;
    uint_fast64_t sigB;
    bool signC;
    int_fast16_t expC;
    uint_fast64_t sigC;
    bool signProd;
    uint_fast64_t magBits, uiZ;
    struct exp16_sig64 normExpSig;
    int_fast16_t expProd;
    struct uint128 sigProd;
    bool signZ;
    int_fast16_t expZ;
    uint_fast64_t sigZ;
    int_fast16_t expDiff;
    struct uint128 sigC128, sigZ128;
    int shiftCount;
    union ui64_f64 uZ;

    signA = signF64UI( uiA );
    expA = expF64UI( uiA );
    sigA = fracF64UI( uiA );
    signB = signF64UI( uiB );
    expB = expF64UI( uiB );
    sigB = fracF64UI( uiB );
    signC = signF64UI( uiC ) ^ (( op & softfloat_mulAdd_subC ) != 0);
    expC = expF64UI( uiC );
    sigC = fracF64UI( uiC );
    signProd = signA ^ signB ^ ( ( op & softfloat_mulAdd_subProd ) != 0);
    if ( expA == 0x7FF ) {
        if ( sigA || ( ( expB == 0x7FF ) && sigB ) ) goto propagateNaN_ABC;
        magBits = expB | sigB;
        goto infProdArg;
    }
    if ( expB == 0x7FF ) {
        if ( sigB ) goto propagateNaN_ABC;
        magBits = expA | sigA;
        goto infProdArg;
    }
    if ( expC == 0x7FF ) {
        if ( sigC ) {
            uiZ = 0;
            goto propagateNaN_ZC;
        }
        uiZ = uiC;
        goto uiZ;
    }
    if ( ! expA ) {
        if ( ! sigA ) goto zeroProd;
        normExpSig = softfloat_normSubnormalF64Sig( sigA );
        expA = normExpSig.exp;
        sigA = normExpSig.sig;
    }
    if ( ! expB ) {
        if ( ! sigB ) goto zeroProd;
        normExpSig = softfloat_normSubnormalF64Sig( sigB );
        expB = normExpSig.exp;
        sigB = normExpSig.sig;
    }
    expProd = expA + expB - 0x3FE;
    sigA = ( sigA | UINT64_C( 0x0010000000000000 ) )<<10;
    sigB = ( sigB | UINT64_C( 0x0010000000000000 ) )<<10;
    sigProd = softfloat_mul64To128( sigA, sigB );
    if ( sigProd.v64 < UINT64_C( 0x2000000000000000 ) ) {
        --expProd;
        sigProd = softfloat_shortShift128Left( sigProd.v64, sigProd.v0, 1 );
    }
    signZ = signProd;
    if ( ! expC ) {
        if ( ! sigC ) {
            expZ = expProd - 1;
            sigZ = sigProd.v64<<1 | ( sigProd.v0 != 0 );
            goto roundPack;
        }
        normExpSig = softfloat_normSubnormalF64Sig( sigC );
        expC = normExpSig.exp;
        sigC = normExpSig.sig;
    }
    sigC = ( sigC | UINT64_C( 0x0010000000000000 ) )<<9;
    expDiff = expProd - expC;
    if ( signProd == signC ) {
        if ( expDiff <= 0 ) {
            expZ = expC;
            if ( expDiff ) {
                sigProd.v64 =
                    softfloat_shift64RightJam( sigProd.v64, - expDiff );
            }
            sigZ = ( sigC + sigProd.v64 ) | ( sigProd.v0 != 0 );
        } else {
            expZ = expProd;
            sigC128 = softfloat_shift128RightJam( sigC, 0, expDiff );
            sigZ128 =
                softfloat_add128(
                    sigProd.v64, sigProd.v0, sigC128.v64, sigC128.v0 );
            sigZ = sigZ128.v64 | ( sigZ128.v0 != 0 );
        }
        if ( sigZ < UINT64_C( 0x4000000000000000 ) ) {
            --expZ;
            sigZ <<= 1;
        }
    } else {
/*** OPTIMIZE BETTER? ***/
        if ( expDiff < 0 ) {
            signZ = signC;
            expZ = expC;
            sigProd =
                softfloat_shift128RightJam(
                    sigProd.v64, sigProd.v0, - expDiff );
            sigZ128 = softfloat_sub128( sigC, 0, sigProd.v64, sigProd.v0 );
        } else if ( ! expDiff ) {
            expZ = expProd;
            sigZ128 = softfloat_sub128( sigProd.v64, sigProd.v0, sigC, 0 );
            if ( ! ( sigZ128.v64 | sigZ128.v0 ) ) goto completeCancellation;
            if ( sigZ128.v64 & UINT64_C( 0x8000000000000000 ) ) {
                signZ ^= 1;
                sigZ128 = softfloat_sub128( 0, 0, sigZ128.v64, sigZ128.v0 );
            }
        } else {
            expZ = expProd;
            sigC128 = softfloat_shift128RightJam( sigC, 0, expDiff );
            sigZ128 =
                softfloat_sub128(
                    sigProd.v64, sigProd.v0, sigC128.v64, sigC128.v0 );
        }
        if ( ! sigZ128.v64 ) {
            expZ -= 64;
            sigZ128.v64 = sigZ128.v0;
            sigZ128.v0 = 0;
        }
        shiftCount = softfloat_countLeadingZeros64( sigZ128.v64 ) - 1;
        expZ -= shiftCount;
        if ( shiftCount < 0 ) {
            sigZ = softfloat_shortShift64RightJam( sigZ128.v64, - shiftCount );
        } else {
            sigZ128 =
                softfloat_shortShift128Left(
                    sigZ128.v64, sigZ128.v0, shiftCount );
            sigZ = sigZ128.v64;
        }
        sigZ |= ( sigZ128.v0 != 0 );
    }
 roundPack:
    return softfloat_roundPackToF64( signZ, expZ, sigZ );
 propagateNaN_ABC:
    uiZ = softfloat_propagateNaNF64UI( uiA, uiB );
    goto propagateNaN_ZC;
 infProdArg:
    if ( magBits ) {
        uiZ = packToF64UI( signProd, 0x7FF, 0 );
        if ( expC != 0x7FF ) goto uiZ;
        if ( sigC ) goto propagateNaN_ZC;
        if ( signProd == signC ) goto uiZ;
    }
 invalid:
    softfloat_raiseFlags( softfloat_flag_invalid );
    uiZ = defaultNaNF64UI;
 propagateNaN_ZC:
    uiZ = softfloat_propagateNaNF64UI( uiZ, uiC );
    goto uiZ;
 zeroProd:
    uiZ = uiC;
    if ( ! ( expC | sigC ) && ( signProd != signC ) ) {
 completeCancellation:
        uiZ =
            packToF64UI( softfloat_roundingMode == softfloat_round_min, 0, 0 );
    }
 uiZ:
    uZ.ui = uiZ;
    return uZ.f;

}

