
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

uint32_t softfloat_shift32RightJam( uint32_t a, unsigned int count )
{

    return
        ( count < 32 )
            ? a>>count | ( (uint32_t) ( a<<( ( - count ) & 31 ) ) != 0 )
            : ( a != 0 );

}

