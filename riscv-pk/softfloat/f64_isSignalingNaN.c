
#include <stdbool.h>
#include "platform.h"
#include "internals.h"
#include "specialize.h"
#include "softfloat.h"

bool f64_isSignalingNaN( float64_t a )
{
    union ui64_f64 uA;

    uA.f = a;
    return softfloat_isSigNaNF64UI( uA.ui );

}

