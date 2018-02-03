#include <assert.h>
#include <defs.h>
#include <stdio.h>

/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
    cprintf("  etext  0x%08x (virtual)\n", etext);
    cprintf("  edata  0x%08x (virtual)\n", edata);
    cprintf("  end    0x%08x (virtual)\n", end);
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
}

/* *
 * print_debuginfo - read and print the stat information for the address @eip,
 * and info.eip_fn_addr should be the first address of the related function.
 * */
void print_debuginfo(uintptr_t eip) { panic("Not Implemented!"); }

/* *
 * print_stackframe - print a list of the saved eip values from the nested
 * 'call'
 * instructions that led to the current point of execution
 *
 * The x86 stack pointer, namely esp, points to the lowest location on the stack
 * that is currently in use. Everything below that location in stack is free.
 * Pushing
 * a value onto the stack will invole decreasing the stack pointer and then
 * writing
 * the value to the place that stack pointer pointes to. And popping a value do
 * the
 * opposite.
 *
 * The ebp (base pointer) register, in contrast, is associated with the stack
 * primarily by software convention. On entry to a C function, the function's
 * prologue code normally saves the previous function's base pointer by pushing
 * it onto the stack, and then copies the current esp value into ebp for the
 * duration
 * of the function. If all the functions in a program obey this convention,
 * then at any given point during the program's execution, it is possible to
 * trace
 * back through the stack by following the chain of saved ebp pointers and
 * determining
 * exactly what nested sequence of function calls caused this particular point
 * in the
 * program to be reached. This capability can be particularly useful, for
 * example,
 * when a particular function causes an assert failure or panic because bad
 * arguments
 * were passed to it, but you aren't sure who passed the bad arguments. A stack
 * backtrace lets you find the offending function.
 *
 * The inline function read_ebp() can tell us the value of current ebp. And the
 * non-inline function read_eip() is useful, it can read the value of current
 * eip,
 * since while calling this function, read_eip() can read the caller's eip from
 * stack easily.
 *
 * In print_debuginfo(), the function debuginfo_eip() can get enough information
 * about
 * calling-chain. Finally print_stackframe() will trace and print them for
 * debugging.
 *
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
    /* LAB1 YOUR CODE : STEP 1 */
    /* (1) call read_ebp() to get the value of ebp. the type is (uint32_t);
     * (2) call read_eip() to get the value of eip. the type is (uint32_t);
     * (3) from 0 .. STACKFRAME_DEPTH
     *    (3.1) printf value of ebp, eip
     *    (3.2) (uint32_t)calling arguments [0..4] = the contents in address
     * (unit32_t)ebp +2 [0..4]
     *    (3.3) cprintf("\n");
     *    (3.4) call print_debuginfo(eip-1) to print the C calling function name
     * and line number, etc.
     *    (3.5) popup a calling stackframe
     *           NOTICE: the calling funciton's return addr eip  = ss:[ebp+4]
     *                   the calling funciton's ebp = ss:[ebp]
     */
    panic("Not Implemented!");
}
