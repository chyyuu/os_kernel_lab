#include <defs.h>
#include <stdio.h>
#include <string.h>
#include <console.h>
#include <kdebug.h>
#include <picirq.h>
#include <trap.h>
#include <clock.h>
#include <intr.h>
#include <pmm.h>
#include <proc.h>
#include <kmonitor.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);

    cons_init();                // init the console

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);

    print_kerninfo();
    pmm_init();                 // init physical memory management
    pic_init();                 // init interrupt controller
    idt_init();                 // init interrupt descriptor table
    proc_init();                // init process table
    clock_init();               // init clock interrupt
    intr_enable();              // enable irq interrupt

	schedule();   //let init proc run
	while (do_wait(1, NULL) == 0) {
        schedule();
    }
}
