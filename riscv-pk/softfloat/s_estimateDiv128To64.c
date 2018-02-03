
#include <stdint.h>
#include "platform.h"
#include "primitives.h"

uint64_t softfloat_estimateDiv128To64( uint64_t a64, uint64_t a0, uint64_t b )
{
    uint32_t b32;
    uint64_t z;
    struct uint128 term, rem;
    uint64_t rem32;

    if ( b <= a64 ) return UINT64_C( 0xFFFFFFFFFFFFFFFF );
    b32 = b>>32;
    z = ( (uint64_t) b32<<32 <= a64 ) ? UINT64_C( 0xFFFFFFFF00000000 )
            : ( a64 / b32 )<<32;
    term = softfloat_mul64To128( b, z );
    rem = softfloat_sub128( a64, a0, term.v64, term.v0 );
    while ( UINT64_C( 0x8000000000000000 ) <= rem.v64 ) {
        z -= UINT64_C( 0x100000000 );
        rem = softfloat_add128( rem.v64, rem.v0, b32, (uint64_t) ( b<<32 ) );
    }
    rem32 = ( rem.v64<<32 ) | ( rem.v0>>32 );
    z |= ( (uint64_t) b32<<32 <= rem32 ) ? 0xFFFFFFFF : rem32 / b32;
    return z;

}

