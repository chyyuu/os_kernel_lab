#ifndef __KERN_FS_SWAPFS_H__
#define __KERN_FS_SWAPFS_H__

#include <memlayout.h>
#include <swap.h>

void swapfs_init(void);
int swapfs_read(swap_entry_t entry, struct Page *page);
int swapfs_write(swap_entry_t entry, struct Page *page);
swap_entry_t swapfs_alloc_entry(void);
void swapfs_free_entry(swap_entry_t entry);

#endif /* !__KERN_FS_SWAPFS_H__ */
