#include <stdio.h>
#include <ulib.h>

/* try to load the kernel's TSS selector into the DS register */

int
main(void) {
	// There is no such thing as TSS in RISC-V
    // asm volatile("movw $0x28,%ax; movw %ax,%ds");
    panic("FAIL: T.T\n");
}

