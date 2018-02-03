
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

uint_fast64_t f64_to_ui64_r_minMag( float64_t a, bool exact )
{
    union ui64_f64 uA;
    uint_fast64_t uiA;
    int_fast16_t exp;
    uint_fast64_t sig;
    int_fast16_t shiftCount;
    uint_fast64_t z;

    uA.f = a;
    uiA = uA.ui;
    exp = expF64UI( uiA );
    sig = fracF64UI( uiA );
    if ( exp < 0x3FF ) {
        if ( exact && ( exp | sig ) ) {
            softfloat_raiseFlags( softfloat_flag_inexact );
        }
        return 0;
    }
    if ( signF64UI( uiA ) ) goto invalid;
    shiftCount = exp - 0x433;
    if ( 0 <= shiftCount ) {
        if ( 0x43E < exp ) goto invalid;
        z = ( sig | UINT64_C( 0x0010000000000000 ) )<<shiftCount;
    } else {
        sig |= UINT64_C( 0x0010000000000000 );
        z = sig>>( - shiftCount );
        if ( exact && (uint64_t) ( sig<<( shiftCount & 63 ) ) ) {
            softfloat_raiseFlags( softfloat_flag_inexact );
        }
    }
    return z;
 invalid:
    softfloat_raiseFlags( softfloat_flag_invalid );
    return UINT64_C( 0xFFFFFFFFFFFFFFFF );

}

