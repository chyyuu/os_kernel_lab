#include <swap.h>
#include <swapfs.h>
#include <mmu.h>
#include <fs.h>
#include <ide.h>
#include <pmm.h>
#include <assert.h>
#include <string.h>

static uint32_t swapfs_bitmap[1024]; // swap is 128 MB = 32768 pages
static size_t swapfs_nr_free;

void
swapfs_init(void) {
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
    memset(swapfs_bitmap, 0, sizeof(swapfs_bitmap));
    swapfs_nr_free = max_swap_offset - 1; // entry 0 is not available
}

int
swapfs_read(swap_entry_t entry, struct Page *page) {
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
}

int
swapfs_write(swap_entry_t entry, struct Page *page) {
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
}

swap_entry_t
swapfs_alloc_entry(void) {
    if (swapfs_nr_free == 0) {
        panic("no free space on swap fs!\n");
    }

    for (int offset = 1; offset < max_swap_offset; ++offset) {
        if (!test_bit(offset, swapfs_bitmap)) {
            set_bit(offset, swapfs_bitmap);
            --swapfs_nr_free;
            swap_entry_t entry = offset << 8;
            return entry;
        }
    }

    return 0;
}

void 
swapfs_free_entry(swap_entry_t entry) {
    size_t offset = swap_offset(entry);
    clear_bit(offset, swapfs_bitmap);
    ++swapfs_nr_free;
}