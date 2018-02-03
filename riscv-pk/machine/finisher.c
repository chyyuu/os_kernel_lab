#include <string.h>
#include "finisher.h"
#include "fdt.h"

volatile uint32_t* finisher;

void finisher_exit(uint16_t code)
{
  if (!finisher) return;
  if (code == 0) {
    *finisher = FINISHER_PASS;
  } else {
    *finisher = code << 16 | FINISHER_FAIL;
  }
}

struct finisher_scan
{
  int compat;
  uint64_t reg;
};

static void finisher_open(const struct fdt_scan_node *node, void *extra)
{
  struct finisher_scan *scan = (struct finisher_scan *)extra;
  memset(scan, 0, sizeof(*scan));
}

static void finisher_prop(const struct fdt_scan_prop *prop, void *extra)
{
  struct finisher_scan *scan = (struct finisher_scan *)extra;
  if (!strcmp(prop->name, "compatible") && !strcmp((const char*)prop->value, "sifive,test0")) {
    scan->compat = 1;
  } else if (!strcmp(prop->name, "reg")) {
    fdt_get_address(prop->node->parent, prop->value, &scan->reg);
  }
}

static void finisher_done(const struct fdt_scan_node *node, void *extra)
{
  struct finisher_scan *scan = (struct finisher_scan *)extra;
  if (!scan->compat || !scan->reg || finisher) return;
  finisher = (uint32_t*)(uintptr_t)scan->reg;
}

void query_finisher(uintptr_t fdt)
{
  struct fdt_cb cb;
  struct finisher_scan scan;

  memset(&cb, 0, sizeof(cb));
  cb.open = finisher_open;
  cb.prop = finisher_prop;
  cb.done = finisher_done;
  cb.extra = &scan;

  fdt_scan(fdt, &cb);
}
