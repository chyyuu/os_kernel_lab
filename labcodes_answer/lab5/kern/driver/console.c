#include <sbi.h>
#include <sync.h>
#include <defs.h>
#include <console.h>

/* kbd_intr - try to feed input characters from keyboard */
void kbd_intr(void) {}

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}

/* *
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
