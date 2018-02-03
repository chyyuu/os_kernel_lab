
#include <stdbool.h>
#include <stdint.h>
#include "platform.h"
#include "internals.h"
#include "softfloat.h"

float32_t f32_add( float32_t a, float32_t b )
{
    union ui32_f32 uA;
    uint_fast32_t uiA;
    bool signA;
    union ui32_f32 uB;
    uint_fast32_t uiB;
    bool signB;
    float32_t ( *magsRoutine )( uint_fast32_t, uint_fast32_t, bool );

    uA.f = a;
    uiA = uA.ui;
    signA = signF32UI( uiA );
    uB.f = b;
    uiB = uB.ui;
    signB = signF32UI( uiB );
    magsRoutine =
        ( signA == signB ) ? softfloat_addMagsF32 : softfloat_subMagsF32;
    return magsRoutine( uiA, uiB, signA );

}

