#include "htif.h"
#include "atomic.h"
#include <string.h>

volatile extern uint64_t tohost;
volatile extern uint64_t fromhost;
volatile int htif_console_buf;
static spinlock_t htif_lock = SPINLOCK_INIT;
uintptr_t htif;

static void __check_fromhost()
{
  uint64_t fh = fromhost;
  if (!fh)
    return;
  fromhost = 0;

  // this should be from the console
  switch (FROMHOST_CMD(fh)) {
    case 0:
      htif_console_buf = 1 + (uint8_t)FROMHOST_DATA(fh);
      break;
    case 1:
      break;
  }
}

static void __set_tohost(uintptr_t dev, uintptr_t cmd, uintptr_t data)
{
  while (tohost)
    __check_fromhost();
  tohost = TOHOST_CMD(dev, cmd, data);
}

void htif_console_putchar(uint8_t ch)
{
  spinlock_lock(&htif_lock);
    __set_tohost(1, 1, ch);
  spinlock_unlock(&htif_lock);
}

void htif_poweroff()
{
  while (1) {
    fromhost = 0;
    tohost = 1;
  }
}

