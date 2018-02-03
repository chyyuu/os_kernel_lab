
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

uint64_t softfloat_shift64RightJam( uint64_t a, unsigned int count )
{

    return
        ( count < 64 )
            ? a>>count | ( (uint64_t) ( a<<( ( - count ) & 63 ) ) != 0 )
            : ( a != 0 );

}

