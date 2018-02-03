
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

uint_fast64_t
 softfloat_roundPackToUI64(
     bool sign,
     uint_fast64_t sig64,
     uint_fast64_t sig0,
     int_fast8_t roundingMode,
     bool exact
 )
{
    bool roundNearestEven, increment;

    roundNearestEven = ( roundingMode == softfloat_round_nearest_even );
    increment = ( UINT64_C( 0x8000000000000000 ) <= sig0 );
    if (
           ! roundNearestEven
        && ( roundingMode != softfloat_round_nearest_maxMag )
    ) {
        increment =
               ( roundingMode != softfloat_round_minMag )
            && ( roundingMode
                     == ( sign ? softfloat_round_min : softfloat_round_max ) )
            && sig0;
    }
    if ( increment ) {
        ++sig64;
        if ( ! sig64 ) goto invalid;
        sig64 &=
            ~ ( ! ( sig0 & UINT64_C( 0x7FFFFFFFFFFFFFFF ) )
                    & roundNearestEven );
    }
    if ( sign && sig64 ) goto invalid;
    if ( exact && sig0 ) softfloat_raiseFlags( softfloat_flag_inexact );
    return sig64;
 invalid:
    softfloat_raiseFlags( softfloat_flag_invalid );
    return UINT64_C( 0xFFFFFFFFFFFFFFFF );

}

