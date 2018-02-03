
/*** UPDATE COMMENTS. ***/

#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

/*----------------------------------------------------------------------------
| Takes two single-precision floating-point values `a' and `b', one of which
| is a NaN, and returns the appropriate NaN result.  If either `a' or `b' is a
| signaling NaN, the invalid exception is raised.
*----------------------------------------------------------------------------*/

uint_fast32_t
 softfloat_propagateNaNF32UI( uint_fast32_t uiA, uint_fast32_t uiB )
{
    bool isNaNA, isSigNaNA, isNaNB, isSigNaNB;
    uint_fast32_t uiMagA, uiMagB;

    /*------------------------------------------------------------------------
    *------------------------------------------------------------------------*/
    isNaNA = isNaNF32UI( uiA );
    isSigNaNA = softfloat_isSigNaNF32UI( uiA );
    isNaNB = isNaNF32UI( uiB );
    isSigNaNB = softfloat_isSigNaNF32UI( uiB );
    /*------------------------------------------------------------------------
    | Make NaNs non-signaling.
    *------------------------------------------------------------------------*/
    uiA |= 0x00400000;
    uiB |= 0x00400000;
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
        uiMagA = uiA<<1;
        uiMagB = uiB<<1;
        if ( uiMagA < uiMagB ) return uiB;
        if ( uiMagB < uiMagA ) return uiA;
        return ( uiA < uiB ) ? uiA : uiB;
    } else {
        return uiB;
    }

}

