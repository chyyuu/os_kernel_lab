#include <defs.h>
#include <x86.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_extclk.h>
#include <list.h>

/*LAB3 EXERCISE 2: 2015011278*/

static extclk_priv_t pra_priv;

static int
__init_mm(struct mm_struct *mm)
{     
     list_init(&pra_priv.list_head);
     pra_priv.clk_ptr = &pra_priv.list_head;
     pra_priv.all_pages_in_list = 0;
     mm->sm_priv = &pra_priv;
     return 0;
}

static int
__map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    if (((extclk_priv_t *)mm->sm_priv)->all_pages_in_list) return 0;

    list_entry_t *head = &((extclk_priv_t *)mm->sm_priv)->list_head;
    list_entry_t *entry = &(page->pra_page_link);
 
    assert(entry != NULL && head != NULL);
    list_add_before(head, entry);
    return 0;
}

static int
__swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
    ((extclk_priv_t *)mm->sm_priv)->all_pages_in_list = 1; // once page fault occurred, all pages are in list.

    list_entry_t *head = &((extclk_priv_t *)mm->sm_priv)->list_head;
    list_entry_t **clk_ptr_ptr = &((extclk_priv_t *)mm->sm_priv)->clk_ptr;
    assert(list_next(head) != head);
    for (; ; *clk_ptr_ptr = list_next(*clk_ptr_ptr)) {
        if (*clk_ptr_ptr == head) continue;

        struct Page *p = le2page(*clk_ptr_ptr, pra_page_link);
        pte_t *ptep = get_pte(mm->pgdir, p->pra_vaddr, 0);
        assert(*ptep & PTE_P);
        cprintf("visit virt: 0x%08x pte flags: %c%c\n",
                p->pra_vaddr, *ptep & PTE_A ? 'A' : '-', *ptep & PTE_D ? 'D' : '-');
        if (!(*ptep & PTE_A)) {
            *ptr_page = p;
            *clk_ptr_ptr = list_next(*clk_ptr_ptr);
            break;
        } else {
            *ptep &= ~PTE_A;
            tlb_invalidate(mm->pgdir, p->pra_vaddr);
        }
    }
    return 0;
}

static int
__check_swap(void) {
    assert(pgfault_num == 4);
    cprintf("write Virt Page c in fifo_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num == 4);
    cprintf("write Virt Page a in fifo_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 4);
    cprintf("write Virt Page d in fifo_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num == 4);
    cprintf("write Virt Page b in fifo_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 4);
    cprintf("write Virt Page e in fifo_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num == 5);
    cprintf("write Virt Page b in fifo_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 5);
    cprintf("write Virt Page a in fifo_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 6);
    cprintf("write Virt Page b in fifo_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 6);
    cprintf("write Virt Page c in fifo_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num == 7);
    cprintf("write Virt Page d in fifo_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num == 8);
    cprintf("write Virt Page e in fifo_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num == 9);
    cprintf("write Virt Page a in fifo_check_swap\n");
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 9);
    return 0;
}


static int
__init(void)
{
    return 0;
}

static int
__set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

static int
__tick_event(struct mm_struct *mm)
{ return 0; }


struct swap_manager swap_manager_extclk =
{
     .name            = "extended clock swap manager",
     .init            = &__init,
     .init_mm         = &__init_mm,
     .tick_event      = &__tick_event,
     .map_swappable   = &__map_swappable,
     .set_unswappable = &__set_unswappable,
     .swap_out_victim = &__swap_out_victim,
     .check_swap      = &__check_swap,
};
