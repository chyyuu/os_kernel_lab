
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
    if ( softfloat_isSigNaNF32UI( uiA ) | softfloat_isSigNaNF32UI( uiB ) ) {
        softfloat_raiseFlags( softfloat_flag_invalid );
    }
    return defaultNaNF32UI;
}

