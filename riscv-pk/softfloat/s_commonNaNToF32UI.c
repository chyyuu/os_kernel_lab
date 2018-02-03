
#include <stdint.h>
#include "platform.h"
#include "specialize.h"

/*----------------------------------------------------------------------------
| Returns the result of converting the canonical NaN `a' to the single-
| precision floating-point format.
*----------------------------------------------------------------------------*/

uint_fast32_t softfloat_commonNaNToF32UI( struct commonNaN a )
{

    return (uint_fast32_t) a.sign<<31 | 0x7FFFFFFF;

}

