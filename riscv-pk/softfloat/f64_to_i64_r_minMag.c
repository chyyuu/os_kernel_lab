
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

int_fast64_t f64_to_i64_r_minMag( float64_t a, bool exact )
{
    union ui64_f64 uA;
    uint_fast64_t uiA;
    bool sign;
    int_fast16_t exp;
    uint_fast64_t sig;
    int_fast16_t shiftCount;
    int_fast64_t absZ;

    uA.f = a;
    uiA = uA.ui;
    sign = signF64UI( uiA );
    exp = expF64UI( uiA );
    sig = fracF64UI( uiA );
    shiftCount = exp - 0x433;
    if ( 0 <= shiftCount ) {
        if ( 0x43E <= exp ) {
            if ( uiA != packToF64UI( 1, 0x43E, 0 ) ) {
                softfloat_raiseFlags( softfloat_flag_invalid );
                if ( ! sign || ( ( exp == 0x7FF ) && sig ) ) {
                    return INT64_C( 0x7FFFFFFFFFFFFFFF );
                }
            }
            return - INT64_C( 0x7FFFFFFFFFFFFFFF ) - 1;
        }
        sig |= UINT64_C( 0x0010000000000000 );
        absZ = sig<<shiftCount;
    } else {
        if ( exp < 0x3FF ) {
            if ( exact && ( exp | sig ) ) {
                softfloat_raiseFlags( softfloat_flag_inexact );
            }
            return 0;
        }
        sig |= UINT64_C( 0x0010000000000000 );
        absZ = sig>>( - shiftCount );
        if ( exact && (uint64_t) ( sig<<( shiftCount & 63 ) ) ) {
            softfloat_raiseFlags( softfloat_flag_inexact );
        }
    }
    return sign ? - absZ : absZ;

}

