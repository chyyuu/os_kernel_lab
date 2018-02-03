
/*============================================================================

*** FIX.

This C source fragment is part of the SoftFloat IEC/IEEE Floating-point
Arithmetic Package, Release 2b.

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
INSTITUTE (possibly via similar legal warning) AGAINST ALL LOSSES, COSTS, OR
OTHER PROBLEMS INCURRED BY THEIR CUSTOMERS AND CLIENTS DUE TO THE SOFTWARE.

Derivative works are acceptable, even for commercial purposes, so long as
(1) the source code for the derivative work includes prominent notice that
the work is derivative, and (2) the source code includes prominent notice with
these four paragraphs for those parts of this code that are retained.

=============================================================================*/

#include <stdbool.h>
#include <stdint.h>

/*----------------------------------------------------------------------------
*----------------------------------------------------------------------------*/
#define init_detectTininess softfloat_tininess_afterRounding;

/*----------------------------------------------------------------------------
| Structure used to transfer NaN representations from one format to another.
*----------------------------------------------------------------------------*/
struct commonNaN {
    bool sign;
    uint64_t v64, v0;
};

/*----------------------------------------------------------------------------
| The pattern for a default generated single-precision NaN.
*----------------------------------------------------------------------------*/
#define defaultNaNF32UI 0xFFC00000

/*----------------------------------------------------------------------------
| Returns 1 if the single-precision floating-point value `a' is a signaling
| NaN; otherwise, returns 0.
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 1 <= INLINE_LEVEL )
INLINE bool softfloat_isSigNaNF32UI( uint_fast32_t ui )
    { return ( ( ui>>22 & 0x1FF ) == 0x1FE ) && ( ui & 0x003FFFFF ); }
#else
bool softfloat_isSigNaNF32UI( uint_fast32_t );
#endif

/*----------------------------------------------------------------------------
*----------------------------------------------------------------------------*/
struct commonNaN softfloat_f32UIToCommonNaN( uint_fast32_t );
#if defined INLINE_LEVEL && ( 1 <= INLINE_LEVEL )
INLINE uint_fast32_t softfloat_commonNaNToF32UI( struct commonNaN a )
    { return (uint_fast32_t) a.sign<<31 | 0x7FC00000 | a.v64>>41; }
#else
uint_fast32_t softfloat_commonNaNToF32UI( struct commonNaN );
#endif

/*----------------------------------------------------------------------------
| Takes two single-precision floating-point values `a' and `b', one of which
| is a NaN, and returns the appropriate NaN result.  If either `a' or `b' is a
| signaling NaN, the invalid exception is raised.
*----------------------------------------------------------------------------*/
uint_fast32_t softfloat_propagateNaNF32UI( uint_fast32_t, uint_fast32_t );

/*----------------------------------------------------------------------------
| The pattern for a default generated double-precision NaN.
*----------------------------------------------------------------------------*/
#define defaultNaNF64UI UINT64_C(0xFFF8000000000000)

/*----------------------------------------------------------------------------
*----------------------------------------------------------------------------*/
#if defined INLINE_LEVEL && ( 1 <= INLINE_LEVEL )
INLINE bool softfloat_isSigNaNF64UI( uint_fast64_t ui )
{
    return
        ( ( ui>>51 & 0xFFF ) == 0xFFE )
            && ( ui & UINT64_C( 0x0007FFFFFFFFFFFF ) );
}
#else
bool softfloat_isSigNaNF64UI( uint_fast64_t );
#endif

/*----------------------------------------------------------------------------
*----------------------------------------------------------------------------*/
/*** MIGHT BE INLINE'D. ***/
struct commonNaN softfloat_f64UIToCommonNaN( uint_fast64_t );
uint_fast64_t softfloat_commonNaNToF64UI( struct commonNaN );

/*----------------------------------------------------------------------------
| Takes two double-precision floating-point values `a' and `b', one of which
| is a NaN, and returns the appropriate NaN result.  If either `a' or `b' is a
| signaling NaN, the invalid exception is raised.
*----------------------------------------------------------------------------*/
uint_fast64_t softfloat_propagateNaNF64UI( uint_fast64_t, uint_fast64_t );

