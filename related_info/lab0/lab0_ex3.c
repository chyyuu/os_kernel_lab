#include <stdio.h>

#define STS_IG32        0xE            // 32-bit Interrupt Gate
#define STS_TG32        0xF            // 32-bit Trap Gate

typedef unsigned uint32_t;

#define SETGATE(gate, istrap, sel, off, dpl) {            \
    (gate).gd_off_15_0 = (uint32_t)(off) & 0xffff;        \
    (gate).gd_ss = (sel);                                \
    (gate).gd_args = 0;                                    \
    (gate).gd_rsv1 = 0;                                    \
    (gate).gd_type = (istrap) ? STS_TG32 : STS_IG32;    \
    (gate).gd_s = 0;                                    \
    (gate).gd_dpl = (dpl);                                \
    (gate).gd_p = 1;                                    \
    (gate).gd_off_31_16 = (uint32_t)(off) >> 16;        \
}

 /* Gate descriptors for interrupts and traps */
 struct gatedesc {
    unsigned gd_off_15_0 : 16;        // low 16 bits of offset in segment
    unsigned gd_ss : 16;            // segment selector
    unsigned gd_args : 5;            // # args, 0 for interrupt/trap gates
    unsigned gd_rsv1 : 3;            // reserved(should be zero I guess)
    unsigned gd_type : 4;            // type(STS_{TG,IG32,TG32})
    unsigned gd_s : 1;                // must be 0 (system)
    unsigned gd_dpl : 2;            // descriptor(meaning new) privilege level
    unsigned gd_p : 1;                // Present
    unsigned gd_off_31_16 : 16;        // high bits of offset in segment
 };
 
int
main(void)
{
    unsigned before;
    unsigned intr;
    unsigned after;
    struct gatedesc gintr;
    
    intr=8;
    before=after=0;

    gintr=*((struct gatedesc *)&intr);
    SETGATE(gintr, 0,1,2,3);
    intr=*(unsigned *)&(gintr);
    printf("intr is 0x%x\n",intr);
    printf("gintr is 0x%llx\n",gintr);
    
    return 0;
}

// other examples
//ex1
#if 0
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <cstring>

#define STS_TG32 0xF
#define STS_IG32 0xE
#define SETGATE( gate, istrap, sel, off, dpl) {            \
    (gate).gd_off_15_0 = (uint32_t)(off) & 0xffff;        \
    (gate).gd_ss = (sel);                                \
    (gate).gd_args = 0;                                    \
    (gate).gd_rsv1 = 0;                                    \
    (gate).gd_type = (istrap) ? STS_TG32 : STS_IG32;    \
    (gate).gd_s = 0;                                    \
    (gate).gd_dpl = (dpl);                                \
    (gate).gd_p = 1;                                    \
    (gate).gd_off_31_16 = (uint32_t)(off) >> 16;        \
}
using namespace std;


struct gatedesc {
    unsigned gd_off_15_0 : 16;        // low 16 bits of offset in segment
    unsigned gd_ss : 16;            // segment selector
    unsigned gd_args : 5;            // # args, 0 for interrupt/trap gates
    unsigned gd_rsv1 : 3;            // reserved(should be zero I guess)
    unsigned gd_type : 4;            // type(STS_{TG,IG32,TG32})
    unsigned gd_s : 1;                // must be 0 (system)
    unsigned gd_dpl : 2;            // descriptor(meaning new) privilege level
    unsigned gd_p : 1;                // Present
    unsigned gd_off_31_16 : 16;        // high bits of offset in segment
};





int main()
{   
    gatedesc intr;

    intr.gd_off_15_0 = 8;
    intr.gd_ss = 0;
    intr.gd_args = 0;
    intr.gd_rsv1 = 0;
    intr.gd_type = 0;
    intr.gd_s = 0;
    intr.gd_dpl = 0;
    intr.gd_p = 0;
    intr.gd_off_31_16 = 0;

    SETGATE( intr, 0,1,2,3);

    printf( "%u\n",  intr);
    printf( "%x", intr);



    return 0;
}
#endif

//ex2
#if 0
#include "stdlib.h"

struct gatedesc {
    unsigned gd_off_15_0 : 16;        // low 16 bits of offset in segment
    unsigned gd_ss : 16;            // segment selector
    unsigned gd_args : 5;            // # args, 0 for interrupt/trap gates
    unsigned gd_rsv1 : 3;            // reserved(should be zero I guess)
    unsigned gd_type : 4;            // type(STS_{TG,IG32,TG32})
    unsigned gd_s : 1;                // must be 0 (system)
    unsigned gd_dpl : 2;            // descriptor(meaning new) privilege level
    unsigned gd_p : 1;                // Present
    unsigned gd_off_31_16 : 16;        // high bits of offset in segment
};

typedef struct gatedesc gatedesc;
typedef unsigned int uint32_t;

#define STS_IG32    0xE     // 32-bit Interrupt Gate
#define STS_TG32    0xF     // 32-bit Trap Gate

#define SETGATE(gate, istrap, sel, off, dpl) {            \
    ((gatedesc*)(&gate))->gd_off_15_0 = (uint32_t)(off) & 0xffff;        \
    ((gatedesc*)(&gate))->gd_ss = (sel);                                \
    ((gatedesc*)(&gate))->gd_args = 0;                                    \
    ((gatedesc*)(&gate))->gd_rsv1 = 0;                                    \
    ((gatedesc*)(&gate))->gd_type = (istrap) ? STS_TG32 : STS_IG32;    \
    ((gatedesc*)(&gate))->gd_s = 0;                                    \
    ((gatedesc*)(&gate))->gd_dpl = (dpl);                                \
    ((gatedesc*)(&gate))->gd_p = 1;                                    \
    ((gatedesc*)(&gate))->gd_off_31_16 = (uint32_t)(off) >> 16;        \
}

int main()
{
	unsigned intr;
	intr=8;
	SETGATE(intr, 0,1,2,3);
	printf("%d", intr);
	return 0;
}
#endif
