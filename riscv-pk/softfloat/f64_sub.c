
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

float64_t f64_sub( float64_t a, float64_t b )
{
    union ui64_f64 uA;
    uint_fast64_t uiA;
    bool signA;
    union ui64_f64 uB;
    uint_fast64_t uiB;
    bool signB;
    float64_t ( *magsRoutine )( uint_fast64_t, uint_fast64_t, bool );

    uA.f = a;
    uiA = uA.ui;
    signA = signF64UI( uiA );
    uB.f = b;
    uiB = uB.ui;
    signB = signF64UI( uiB );
    magsRoutine =
        ( signA == signB ) ? softfloat_subMagsF64 : softfloat_addMagsF64;
    return magsRoutine( uiA, uiB, signA );

}

