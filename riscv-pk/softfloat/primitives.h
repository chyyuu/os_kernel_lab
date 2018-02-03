
/*============================================================================

This C source fragment is part of the SoftFloat IEC/IEEE Floating-point
Arithmetic Package, Release 3.

*** UPDATE

Written by John R. Hauser.  This work was made possible in part by the
International Computer Science Institute, located at Suite 600, 1947 Center
Street, Berkeley, California 94704.  Funding was partially provided by the
National Science Foundation under grant MIP-9311980.  The original version
of this code was written as part of a project to build a fixed-point vector
processor in collaboration with the University of California at Berkeley,
overseen by Profs. Nelson Morgan and John Wawrzynek.  More information
is available through the Web page `http://www.cs.berkeley.edu/~jhauser/
arithmetic/SoftFloat.html'.

THIS SOFTWARE IS DISTRIBUTED AS IS, FOR FREE.  Although reasonable effort has
been made to avoid it, THIS SOFTWARE MAY CONTAIN FAULTS THAT WILL AT TIMES
RESULT IN INCORRECT BEHAVIOR.  USE OF THIS SOFTWARE IS RESTRICTED TO PERSONS
AND ORGANIZATIONS WHO CAN AND WILL TAKE FULL RESPONSIBILITY FOR ALL LOSSES,
COSTS, OR OTHER PROBLEMS THEY INCUR DUE TO THE SOFTWARE, AND WHO FURTHERMORE
EFFECTIVELY INDEMNIFY JOHN HAUSER AND THE INTERNATIONAL COMPUTER SCIENCE
INSTITUTE (possibly via similar legal notice) AGAINST ALL LOSSES, COSTS, OR
OTHER PROBLEMS INCURRED BY THEIR CUSTOMERS AND CLIENTS DUE TO THE SOFTWARE.

Derivative works are acceptable, even for commercial purposes, so long as
(1) the source code for the derivative work includes prominent notice that
the work is derivative, and (2) the source code includes prominent notice with
these four paragraphs for those parts of this code that are retained.

=============================================================================*/

#include <stdbool.h>
#include <stdint.h>

/*** CHANGE TO USE `fast' INTEGER TYPES? ***/
/*** ADD 80-BIT FUNCTIONS? ***/

#ifdef LITTLEENDIAN
struct uintx80 { uint64_t v0; uint16_t v64; };
struct uint128 { uint64_t v0, v64; };
struct uint192 { uint64_t v0, v64, v128; };
struct uint256 { uint64_t v0, v64, v128, v192; };
#else
struct uintx80 { uint16_t v64; uint64_t v0; };
struct uint128 { uint64_t v64, v0; };
struct uint192 { uint64_t v128, v64, v0; };
struct uint256 { uint64_t v256, v128, v64, v0; };
#endif

struct uint64_extra { uint64_t v, extra; };
struct uint128_extra { uint64_t v64; uint64_t v0; uint64_t extra; };


/*** SHIFT COUNTS CANNOT BE ZERO.  MUST CHECK BEFORE CALLING! ***/


/*----------------------------------------------------------------------------
| Returns 1 if the 128-bit value formed by concatenating `a0' and `a1'
| is equal to the 128-bit value formed by concatenating `b0' and `b1'.
| Otherwise, returns 0.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 1 <= INLINE_LEVEL )
INLINE bool
 softfloat_eq128( uint64_t a64, uint64_t a0, uint64_t b64, uint64_t b0 )
    { return ( a64 == b64 ) && ( a0 == b0 ); }
#else
bool softfloat_eq128( uint64_t, uint64_t, uint64_t, uint64_t );
#endif

/*----------------------------------------------------------------------------
| Returns 1 if the 128-bit value formed by concatenating `a0' and `a1' is less
| than or equal to the 128-bit value formed by concatenating `b0' and `b1'.
| Otherwise, returns 0.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 1 <= INLINE_LEVEL )
INLINE bool
 softfloat_le128( uint64_t a64, uint64_t a0, uint64_t b64, uint64_t b0 )
    { return ( a64 < b64 ) || ( ( a64 == b64 ) && ( a0 <= b0 ) ); }
#else
bool softfloat_le128( uint64_t, uint64_t, uint64_t, uint64_t );
#endif

/*----------------------------------------------------------------------------
| Returns 1 if the 128-bit value formed by concatenating `a0' and `a1' is less
| than the 128-bit value formed by concatenating `b0' and `b1'.  Otherwise,
| returns 0.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 1 <= INLINE_LEVEL )
INLINE bool
 softfloat_lt128( uint64_t a64, uint64_t a0, uint64_t b64, uint64_t b0 )
    { return ( a64 < b64 ) || ( ( a64 == b64 ) && ( a0 < b0 ) ); }
#else
bool softfloat_lt128( uint64_t, uint64_t, uint64_t, uint64_t );
#endif

/*----------------------------------------------------------------------------
| Shifts the 128-bit value formed by concatenating `a0' and `a1' left by the
| number of bits given in `count'.  Any bits shifted off are lost.  The value
| of `count' must be less than 64.  The result is broken into two 64-bit
| pieces which are stored at the locations pointed to by `z0Ptr' and `z1Ptr'.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 2 <= INLINE_LEVEL )
INLINE struct uint128
 softfloat_shortShift128Left( uint64_t a64, uint64_t a0, unsigned int count )
{
    struct uint128 z;
    z.v64 = a64<<count | a0>>( ( - count ) & 63 );
    z.v0 = a0<<count;
    return z;
}
#else
struct uint128 softfloat_shortShift128Left( uint64_t, uint64_t, unsigned int );
#endif

/*----------------------------------------------------------------------------
| Shifts the 192-bit value formed by concatenating `a0', `a1', and `a2' left
| by the number of bits given in `count'.  Any bits shifted off are lost.
| The value of `count' must be less than 64.  The result is broken into three
| 64-bit pieces which are stored at the locations pointed to by `z0Ptr',
| `z1Ptr', and `z2Ptr'.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 3 <= INLINE_LEVEL )
INLINE struct uint192
 softfloat_shortShift192Left(
     uint64_t a128, uint64_t a64, uint64_t a0, unsigned int count )
{
    unsigned int negCount = - count;
    struct uint192 z;
    z.v128 = a128<<count | a64>>( negCount & 63 );
    z.v64 = a64<<count | a0>>( negCount & 63 );
    z.v0 = a0<<count;
    return z;
}
#else
struct uint192
 softfloat_shortShift192Left( uint64_t, uint64_t, uint64_t, unsigned int );
#endif

/*----------------------------------------------------------------------------
| Shifts `a' right by the number of bits given in `count'.  If any nonzero
| bits are shifted off, they are ``jammed'' into the least significant bit of
| the result by setting the least significant bit to 1.  The value of `count'
| can be arbitrarily large; in particular, if `count' is greater than 32, the
| result will be either 0 or 1, depending on whether `a' is zero or nonzero.
| The result is stored in the location pointed to by `zPtr'.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 2 <= INLINE_LEVEL )
INLINE uint32_t softfloat_shift32RightJam( uint32_t a, unsigned int count )
{
    return
        ( count < 32 )
            ? a>>count | ( (uint32_t) ( a<<( ( - count ) & 31 ) ) != 0 )
            : ( a != 0 );
}
#else
uint32_t softfloat_shift32RightJam( uint32_t, unsigned int );
#endif

/*----------------------------------------------------------------------------
| Shift count is less than 32.
*----------------------------------------------------------------------------*/
#if defined INLINE
INLINE uint32_t softfloat_shortShift32Right1Jam( uint32_t a )
    { return a>>1 | ( a & 1 ); }
#else
uint32_t softfloat_shortShift32Right1Jam( uint32_t );
#endif

/*----------------------------------------------------------------------------
| Shifts `a' right by the number of bits given in `count'.  If any nonzero
| bits are shifted off, they are ``jammed'' into the least significant bit of
| the result by setting the least significant bit to 1.  The value of `count'
| can be arbitrarily large; in particular, if `count' is greater than 64, the
| result will be either 0 or 1, depending on whether `a' is zero or nonzero.
| The result is stored in the location pointed to by `zPtr'.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 3 <= INLINE_LEVEL )
INLINE uint64_t softfloat_shift64RightJam( uint64_t a, unsigned int count )
{
    return
        ( count < 64 )
            ? a>>count | ( (uint64_t) ( a<<( ( - count ) & 63 ) ) != 0 )
            : ( a != 0 );
}
#else
uint64_t softfloat_shift64RightJam( uint64_t, unsigned int );
#endif

/*----------------------------------------------------------------------------
| Shift count is less than 64.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 2 <= INLINE_LEVEL )
INLINE uint64_t
 softfloat_shortShift64RightJam( uint64_t a, unsigned int count )
    { return a>>count | ( ( a & ( ( (uint64_t) 1<<count ) - 1 ) ) != 0 ); }
#else
uint64_t softfloat_shortShift64RightJam( uint64_t, unsigned int );
#endif

/*----------------------------------------------------------------------------
| Shifts the 128-bit value formed by concatenating `a0' and `a1' right by 64
| _plus_ the number of bits given in `count'.  The shifted result is at most
| 64 nonzero bits; this is stored at the location pointed to by `z0Ptr'.  The
| bits shifted off form a second 64-bit result as follows:  The _last_ bit
| shifted off is the most-significant bit of the extra result, and the other
| 63 bits of the extra result are all zero if and only if _all_but_the_last_
| bits shifted off were all zero.  This extra result is stored in the location
| pointed to by `z1Ptr'.  The value of `count' can be arbitrarily large.
|     (This routine makes more sense if `a0' and `a1' are considered to form
| a fixed-point value with binary point between `a0' and `a1'.  This fixed-
| point value is shifted right by the number of bits given in `count', and
| the integer part of the result is returned at the location pointed to by
| `z0Ptr'.  The fractional part of the result may be slightly corrupted as
| described above, and is returned at the location pointed to by `z1Ptr'.)
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 3 <= INLINE_LEVEL )
INLINE struct uint64_extra
 softfloat_shift64ExtraRightJam(
     uint64_t a, uint64_t extra, unsigned int count )
{
    struct uint64_extra z;
    if ( count < 64 ) {
        z.v = a>>count;
        z.extra = a<<( ( - count ) & 63 );
    } else {
        z.v = 0;
        z.extra = ( count == 64 ) ? a : ( a != 0 );
    }
    z.extra |= ( extra != 0 );
    return z;
}
#else
struct uint64_extra
 softfloat_shift64ExtraRightJam( uint64_t, uint64_t, unsigned int );
#endif

/*----------------------------------------------------------------------------
| Shift count is less than 64.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 2 <= INLINE_LEVEL )
INLINE struct uint64_extra
 softfloat_shortShift64ExtraRightJam(
     uint64_t a, uint64_t extra, unsigned int count )
{
    struct uint64_extra z;
    z.v = a>>count;
    z.extra = a<<( ( - count ) & 63 ) | ( extra != 0 );
    return z;
}
#else
struct uint64_extra
 softfloat_shortShift64ExtraRightJam( uint64_t, uint64_t, unsigned int );
#endif

/*----------------------------------------------------------------------------
| Shifts the 128-bit value formed by concatenating `a0' and `a1' right by the
| number of bits given in `count'.  Any bits shifted off are lost.  The value
| of `count' can be arbitrarily large; in particular, if `count' is greater
| than 128, the result will be 0.  The result is broken into two 64-bit pieces
| which are stored at the locations pointed to by `z0Ptr' and `z1Ptr'.
*----------------------------------------------------------------------------*/
/*----------------------------------------------------------------------------
| Shift count is less than 64.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 2 <= INLINE_LEVEL )
INLINE struct uint128
 softfloat_shortShift128Right( uint64_t a64, uint64_t a0, unsigned int count )
{
    struct uint128 z;
    z.v64 = a64>>count;
    z.v0 = a64<<( ( - count ) & 63 ) | a0>>count;
    return z;
}
#else
struct uint128
 softfloat_shortShift128Right( uint64_t, uint64_t, unsigned int );
#endif

/*----------------------------------------------------------------------------
| Shifts the 128-bit value formed by concatenating `a0' and `a1' right by the
| number of bits given in `count'.  If any nonzero bits are shifted off, they
| are ``jammed'' into the least significant bit of the result by setting the
| least significant bit to 1.  The value of `count' can be arbitrarily large;
| in particular, if `count' is greater than 128, the result will be either
| 0 or 1, depending on whether the concatenation of `a0' and `a1' is zero or
| nonzero.  The result is broken into two 64-bit pieces which are stored at
| the locations pointed to by `z0Ptr' and `z1Ptr'.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 4 <= INLINE_LEVEL )
INLINE struct uint128
 softfloat_shift128RightJam( uint64_t a64, uint64_t a0, unsigned int count )
{
    unsigned int negCount;
    struct uint128 z;
    if ( count < 64 ) {
        negCount = - count;
        z.v64 = a64>>( count & 63 );
        z.v0 =
            a64<<( negCount & 63 ) | a0>>count
                | ( (uint64_t) ( a0<<( negCount & 63 ) ) != 0 );
    } else {
        z.v64 = 0;
        z.v0 =
            ( count < 128 )
                ? a64>>( count & 63 )
                      | ( ( ( a64 & ( ( (uint64_t) 1<<( count & 63 ) ) - 1 ) )
                                | a0 )
                              != 0 )
                : ( ( a64 | a0 ) != 0 );
    }
    return z;
}
#else
struct uint128
 softfloat_shift128RightJam( uint64_t, uint64_t, unsigned int );
#endif

/*----------------------------------------------------------------------------
| Shifts the 192-bit value formed by concatenating `a0', `a1', and `a2' right
| by 64 _plus_ the number of bits given in `count'.  The shifted result is
| at most 128 nonzero bits; these are broken into two 64-bit pieces which are
| stored at the locations pointed to by `z0Ptr' and `z1Ptr'.  The bits shifted
| off form a third 64-bit result as follows:  The _last_ bit shifted off is
| the most-significant bit of the extra result, and the other 63 bits of the
| extra result are all zero if and only if _all_but_the_last_ bits shifted off
| were all zero.  This extra result is stored in the location pointed to by
| `z2Ptr'.  The value of `count' can be arbitrarily large.
|     (This routine makes more sense if `a0', `a1', and `a2' are considered
| to form a fixed-point value with binary point between `a1' and `a2'.  This
| fixed-point value is shifted right by the number of bits given in `count',
| and the integer part of the result is returned at the locations pointed to
| by `z0Ptr' and `z1Ptr'.  The fractional part of the result may be slightly
| corrupted as described above, and is returned at the location pointed to by
| `z2Ptr'.)
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 5 <= INLINE_LEVEL )
INLINE struct uint128_extra
 softfloat_shift128ExtraRightJam(
     uint64_t a64, uint64_t a0, uint64_t extra, unsigned int count )
{
    unsigned int negCount = - count;
    struct uint128_extra z;
    if ( count < 64 ) {
        z.v64 = a64>>count;
        z.v0 = a64<<( negCount & 63 ) | a0>>count;
        z.extra = a0<<( negCount & 63 );
    } else {
        z.v64 = 0;
        if ( count == 64 ) {
            z.v0 = a64;
            z.extra = a0;
        } else {
            extra |= a0;
            if ( count < 128 ) {
                z.v0 = a64>>( count & 63 );
                z.extra = a64<<( negCount & 63 );
            } else {
                z.v0 = 0;
                z.extra = ( count == 128 ) ? a64 : ( a64 != 0 );
            }
        }
    }
    z.extra |= ( extra != 0 );
    return z;
}
#else
struct uint128_extra
 softfloat_shift128ExtraRightJam( uint64_t, uint64_t, uint64_t, unsigned int );
#endif

/*----------------------------------------------------------------------------
| Shift count is less than 64.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 3 <= INLINE_LEVEL )
INLINE struct uint128_extra
 softfloat_shortShift128ExtraRightJam(
     uint64_t a64, uint64_t a0, uint64_t extra, unsigned int count )
{
    unsigned int negCount = - count;
    struct uint128_extra z;
    z.v64 = a64>>count;
    z.v0 = a64<<( negCount & 63 ) | a0>>count;
    z.extra = a0<<( negCount & 63 ) | ( extra != 0 );
    return z;
}
#else
struct uint128_extra
 softfloat_shortShift128ExtraRightJam(
     uint64_t, uint64_t, uint64_t, unsigned int );
#endif

extern const uint8_t softfloat_countLeadingZeros8[ 256 ];

/*----------------------------------------------------------------------------
| Returns the number of leading 0 bits before the most-significant 1 bit of
| `a'.  If `a' is zero, 32 is returned.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 2 <= INLINE_LEVEL )
INLINE int softfloat_countLeadingZeros32( uint32_t a )
{
    int count = 0;
    if ( a < 0x10000 ) {
        count = 16;
        a <<= 16;
    }
    if ( a < 0x1000000 ) {
        count += 8;
        a <<= 8;
    }
    count += softfloat_countLeadingZeros8[ a>>24 ];
    return count;
}
#else
int softfloat_countLeadingZeros32( uint32_t );
#endif

/*----------------------------------------------------------------------------
| Returns the number of leading 0 bits before the most-significant 1 bit of
| `a'.  If `a' is zero, 64 is returned.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 4 <= INLINE_LEVEL )
INLINE int softfloat_countLeadingZeros64( uint64_t a )
{
    int count = 32;
    uint32_t a32 = a;
    if ( UINT64_C( 0x100000000 ) <= a ) {
        count = 0;
        a32 = a>>32;
    }
    /*------------------------------------------------------------------------
    | From here, result is current count + count leading zeros of `a32'.
    *------------------------------------------------------------------------*/
    if ( a32 < 0x10000 ) {
        count += 16;
        a32 <<= 16;
    }
    if ( a32 < 0x1000000 ) {
        count += 8;
        a32 <<= 8;
    }
    count += softfloat_countLeadingZeros8[ a32>>24 ];
    return count;
}
#else
int softfloat_countLeadingZeros64( uint64_t );
#endif

/*----------------------------------------------------------------------------
| Adds the 128-bit value formed by concatenating `a0' and `a1' to the 128-bit
| value formed by concatenating `b0' and `b1'.  Addition is modulo 2^128, so
| any carry out is lost.  The result is broken into two 64-bit pieces which
| are stored at the locations pointed to by `z0Ptr' and `z1Ptr'.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 2 <= INLINE_LEVEL )
INLINE struct uint128
 softfloat_add128( uint64_t a64, uint64_t a0, uint64_t b64, uint64_t b0 )
{
    struct uint128 z;
    z.v0 = a0 + b0;
    z.v64 = a64 + b64;
    z.v64 += ( z.v0 < a0 );
    return z;
}
#else
struct uint128 softfloat_add128( uint64_t, uint64_t, uint64_t, uint64_t );
#endif

/*----------------------------------------------------------------------------
| Adds the 192-bit value formed by concatenating `a0', `a1', and `a2' to the
| 192-bit value formed by concatenating `b0', `b1', and `b2'.  Addition is
| modulo 2^192, so any carry out is lost.  The result is broken into three
| 64-bit pieces which are stored at the locations pointed to by `z0Ptr',
| `z1Ptr', and `z2Ptr'.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 3 <= INLINE_LEVEL )
INLINE struct uint192
 softfloat_add192(
     uint64_t a128,
     uint64_t a64,
     uint64_t a0,
     uint64_t b128,
     uint64_t b64,
     uint64_t b0
 )
{
    struct uint192 z;
    unsigned int carry64, carry128;
    z.v0 = a0 + b0;
    carry64 = ( z.v0 < a0 );
    z.v64 = a64 + b64;
    carry128 = ( z.v64 < a64 );
    z.v128 = a128 + b128;
    z.v64 += carry64;
    carry128 += ( z.v64 < carry64 );
    z.v128 += carry128;
    return z;
}
#else
struct uint192
 softfloat_add192(
     uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t );
#endif

/*----------------------------------------------------------------------------
| Subtracts the 128-bit value formed by concatenating `b0' and `b1' from the
| 128-bit value formed by concatenating `a0' and `a1'.  Subtraction is modulo
| 2^128, so any borrow out (carry out) is lost.  The result is broken into two
| 64-bit pieces which are stored at the locations pointed to by `z0Ptr' and
| `z1Ptr'.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 2 <= INLINE_LEVEL )
INLINE struct uint128
 softfloat_sub128( uint64_t a64, uint64_t a0, uint64_t b64, uint64_t b0 )
{
    struct uint128 z;
    z.v0 = a0 - b0;
    z.v64 = a64 - b64;
    z.v64 -= ( a0 < b0 );
    return z;
}
#else
struct uint128 softfloat_sub128( uint64_t, uint64_t, uint64_t, uint64_t );
#endif

/*----------------------------------------------------------------------------
| Subtracts the 192-bit value formed by concatenating `b0', `b1', and `b2'
| from the 192-bit value formed by concatenating `a0', `a1', and `a2'.
| Subtraction is modulo 2^192, so any borrow out (carry out) is lost.  The
| result is broken into three 64-bit pieces which are stored at the locations
| pointed to by `z0Ptr', `z1Ptr', and `z2Ptr'.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 3 <= INLINE_LEVEL )
INLINE struct uint192
 softfloat_sub192(
     uint64_t a128,
     uint64_t a64,
     uint64_t a0,
     uint64_t b128,
     uint64_t b64,
     uint64_t b0
 )
{
    struct uint192 z;
    unsigned int borrow64, borrow128;
    z.v0 = a0 - b0;
    borrow64 = ( a0 < b0 );
    z.v64 = a64 - b64;
    borrow128 = ( a64 < b64 );
    z.v128 = a128 - b128;
    borrow128 += ( z.v64 < borrow64 );
    z.v64 -= borrow64;
    z.v128 -= borrow128;
    return z;
}
#else
struct uint192
 softfloat_sub192(
     uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t );
#endif

/*----------------------------------------------------------------------------
| Multiplies `a' by `b' to obtain a 128-bit product.  The product is broken
| into two 64-bit pieces which are stored at the locations pointed to by
| `z0Ptr' and `z1Ptr'.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 4 <= INLINE_LEVEL )
INLINE struct uint128 softfloat_mul64To128( uint64_t a, uint64_t b )
{
    uint32_t a32 = a>>32;
    uint32_t a0 = a;
    uint32_t b32 = b>>32;
    uint32_t b0 = b;
    struct uint128 z;
    uint64_t mid1, mid2, mid;
    z.v0 = (uint64_t) a0 * b0;
    mid1 = (uint64_t) a32 * b0;
    mid2 = (uint64_t) a0 * b32;
    z.v64 = (uint64_t) a32 * b32;
    mid = mid1 + mid2;
    z.v64 += ( (uint64_t) ( mid < mid1 ) )<<32 | mid>>32;
    mid <<= 32;
    z.v0 += mid;
    z.v64 += ( z.v0 < mid );
    return z;
}
#else
struct uint128 softfloat_mul64To128( uint64_t, uint64_t );
#endif

/*----------------------------------------------------------------------------
| Multiplies the 128-bit value formed by concatenating `a0' and `a1' by
| `b' to obtain a 192-bit product.  The product is broken into three 64-bit
| pieces which are stored at the locations pointed to by `z0Ptr', `z1Ptr', and
| `z2Ptr'.
*----------------------------------------------------------------------------*/
struct uint192 softfloat_mul128By64To192( uint64_t, uint64_t, uint64_t );
/*----------------------------------------------------------------------------
| Multiplies the 128-bit value formed by concatenating `a0' and `a1' to the
| 128-bit value formed by concatenating `b0' and `b1' to obtain a 256-bit
| product.  The product is broken into four 64-bit pieces which are stored at
| the locations pointed to by `z0Ptr', `z1Ptr', `z2Ptr', and `z3Ptr'.
*----------------------------------------------------------------------------*/
struct uint256 softfloat_mul128To256( uint64_t, uint64_t, uint64_t, uint64_t );

/*----------------------------------------------------------------------------
| Returns an approximation to the 64-bit integer quotient obtained by dividing
| `b' into the 128-bit value formed by concatenating `a0' and `a1'.  The
| divisor `b' must be at least 2^63.  If q is the exact quotient truncated
| toward zero, the approximation returned lies between q and q + 2 inclusive.
| If the exact quotient q is larger than 64 bits, the maximum positive 64-bit
| unsigned integer is returned.
*----------------------------------------------------------------------------*/
uint64_t softfloat_estimateDiv128To64( uint64_t, uint64_t, uint64_t );

/*----------------------------------------------------------------------------
| Returns an approximation to the square root of the 32-bit significand given
| by `a'.  Considered as an integer, `a' must be at least 2^31.  If bit 0 of
| `aExp' (the least significant bit) is 1, the integer returned approximates
| 2^31*sqrt(`a'/2^31), where `a' is considered an integer.  If bit 0 of `aExp'
| is 0, the integer returned approximates 2^31*sqrt(`a'/2^30).  In either
| case, the approximation returned lies strictly within +/-2 of the exact
| value.
*----------------------------------------------------------------------------*/
uint32_t softfloat_estimateSqrt32( unsigned int, uint32_t );

