#ifndef __KERN_MM_SWAP_EXTCLK_H__
#define __KERN_MM_SWAP_EXTCLK_H__

#include <swap.h>
extern struct swap_manager swap_manager_extclk;

typedef struct extclk_priv {
    list_entry_t list_head;
    list_entry_t *clk_ptr;
    bool all_pages_in_list;
} extclk_priv_t;

#endif
