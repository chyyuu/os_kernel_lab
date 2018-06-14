#include "htif.h"

void putstring(const char* s)
{
    int c;
    while (*s) {
        c = *s++;
        if (c == '\n')
            htif_console_putchar('\r');
        htif_console_putchar(c);
    }
}

void boot_loader(uintptr_t dtb)
{
  putstring("Hello World!\n");
  htif_poweroff(0);
}
