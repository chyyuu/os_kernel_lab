
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

uint64_t softfloat_shortShift64RightJam( uint64_t a, unsigned int count )
{

    return a>>count | ( ( a & ( ( (uint64_t) 1<<count ) - 1 ) ) != 0 );

}

