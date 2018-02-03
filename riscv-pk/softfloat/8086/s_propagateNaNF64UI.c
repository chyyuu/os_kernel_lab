
/*** UPDATE COMMENTS. ***/

#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

/*----------------------------------------------------------------------------
| Takes two double-precision floating-point values `a' and `b', one of which
| is a NaN, and returns the appropriate NaN result.  If either `a' or `b' is a
| signaling NaN, the invalid exception is raised.
*----------------------------------------------------------------------------*/

uint_fast64_t
 softfloat_propagateNaNF64UI( uint_fast64_t uiA, uint_fast64_t uiB )
{
    bool isNaNA, isSigNaNA, isNaNB, isSigNaNB;
    uint_fast64_t uiMagA, uiMagB;

    /*------------------------------------------------------------------------
    *------------------------------------------------------------------------*/
    isNaNA = isNaNF64UI( uiA );
    isSigNaNA = softfloat_isSigNaNF64UI( uiA );
    isNaNB = isNaNF64UI( uiB );
    isSigNaNB = softfloat_isSigNaNF64UI( uiB );
    /*------------------------------------------------------------------------
    | Make NaNs non-signaling.
    *------------------------------------------------------------------------*/
    uiA |= UINT64_C( 0x0008000000000000 );
    uiB |= UINT64_C( 0x0008000000000000 );
    /*------------------------------------------------------------------------
    *------------------------------------------------------------------------*/
    if ( isSigNaNA | isSigNaNB ) {
        softfloat_raiseFlags( softfloat_flag_invalid );
    }
    if ( isSigNaNA ) {
        if ( isSigNaNB ) goto returnLargerSignificand;
        return isNaNB ? uiB : uiA;
    } else if ( isNaNA ) {
        if ( isSigNaNB || ! isNaNB ) return uiA;
 returnLargerSignificand:
        uiMagA = uiA & UINT64_C( 0x7FFFFFFFFFFFFFFF );
        uiMagB = uiB & UINT64_C( 0x7FFFFFFFFFFFFFFF );
        if ( uiMagA < uiMagB ) return uiB;
        if ( uiMagB < uiMagA ) return uiA;
        return ( uiA < uiB ) ? uiA : uiB;
    } else {
        return uiB;
    }

}

