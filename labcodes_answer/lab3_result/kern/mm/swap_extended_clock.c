#include <defs.h>
#include <x86.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_extended_clock.h>
#include <list.h>

list_entry_t *clock_p;
list_entry_t pra_list_head;


static int
_extended_clock_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
     clock_p = (list_entry_t*)&pra_list_head;
     //cprintf(" mm->sm_priv %x in extended_clock_init_mm\n",mm->sm_priv);
     return 0;
}
/*
 * (3)_extended_clock_map_swappable: According extended_clock PRA, we should link the most recent arrival page at the back of pra_list_head qeueue
 */
static int
_extended_clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && head != NULL);

    list_add_before(clock_p, entry);
    //pte_t *pte = get_pte(mm->pgdir, page2kva(page), 0);
	pte_t *pte = get_pte(mm->pgdir, addr, 0);
    int access = (*pte)&(PTE_A)?1:0;
    int dirty = (*pte)&(PTE_D)?1:0;
	
	///*(unsigned char *)0x5000 = 0x2e;
	//cprintf("!!!!!%x\n",page->pra_vaddr);
    //cprintf("+++ i add a entry!  0x%4x A:%d D:%d\n", addr, access, dirty);
    return 0;
}
/*
 *  (4)_extended_clock_swap_out_victim: According extended_clock PRA, we should unlink the  earliest arrival page in front of pra_list_head qeueue,
 *                            then set the addr of addr of this page to ptr_page.
 */
static int
_extended_clock_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     /*LAB3 EXERCISE 2: YOUR CODE*/ 
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
     /* Select the tail */
     list_entry_t *le = clock_p;
//     if (le == le->next)
//    	 cprintf("+++++true\n");
//     else cprintf("+++++false\n");

     le = head->next;
	 //cprintf("++++++++++%x\n",mm->pgdir);
     cprintf("\n---start---\n");
     while (1) {
    	 struct Page *page = le2page(le, pra_page_link);
    	 pte_t * pte = get_pte(mm->pgdir, page->pra_vaddr, 0);
    	 int accessed = (*pte)&(PTE_A)?1:0;
    	 int dirty = (*pte)&(PTE_D)?1:0;
		 if (le==clock_p)
			 cprintf("->");
		 else
			 cprintf("  ");
    	 cprintf("clock state: 0x%4x: A:%x, D:%x\n", page->pra_vaddr, accessed, dirty);
    	 le = le->next;
    	 if (le == head) {
    		 break;
    	 }
     }
     cprintf("----end----\n");

     le = clock_p;
     while (1) {
    	 if (le == head) {
    		 le = le->next;
    		 clock_p = clock_p -> next;
    	 }
    	 struct Page *page = le2page(le, pra_page_link);
//    	 cprintf("hehe0\n");
    	 pte_t * pte = get_pte(mm->pgdir, page->pra_vaddr, 0);
//    	 cprintf("+++++A:%x D:%x\n", (*pte)&(PTE_A), (*pte)&(PTE_D));
//    	 cprintf("+++++pte: %x\n", (*pte));
    	 int accessed = (*pte)&(PTE_A)?1:0;
    	 int dirty = (*pte)&(PTE_D)?1:0;
    	 if (accessed) {
    		 cprintf("clock state: 0x%4x: A:%x, D:%x\n", page->pra_vaddr, accessed, dirty);
    		 (*pte) = (*pte) & (~PTE_A);
    		 cprintf("\tclock state: 0x%4x: A:%x, D:%x\n",page->pra_vaddr, (*pte)&(PTE_A)?1:0, (*pte)&(PTE_D)?1:0);
    	 }
    	 else if (!accessed && dirty) {
    		 cprintf("clock state: 0x%4x: A:%x, D:%x\n", page->pra_vaddr, accessed, dirty);
    		 (*pte) = (*pte) & (~PTE_D);
    		 cprintf("\tclock state: 0x%4x: A:%x, D:%x\n", page->pra_vaddr, (*pte)&(PTE_A)?1:0, (*pte)&(PTE_D)?1:0);
    	 } else if (!accessed && !dirty){
    	     struct Page *p = le2page(le, pra_page_link);
    	     list_del(le);
    	     clock_p = clock_p->next;
    	     assert(p !=NULL);
    	     *ptr_page = p;
			 
			 
			 
			 
			 
			 
			 
			 le = head->next;
			 cprintf("\n--after--start---\n");
			 while (1) {
				 struct Page *page = le2page(le, pra_page_link);
				 pte_t * pte = get_pte(mm->pgdir, page->pra_vaddr, 0);
				 int accessed = (*pte)&(PTE_A)?1:0;
				 int dirty = (*pte)&(PTE_D)?1:0;
				 if (le==clock_p)
					 cprintf("->");
				 else
					 cprintf("  ");
				 cprintf("clock state: 0x%4x: A:%x, D:%x\n", page->pra_vaddr, accessed, dirty);
				 le = le->next;
				 if (le == head) {
					 break;
				 }
			 }
			 cprintf("--after--end----\n");
			 
			 
			 
			 
			 
			 
			 
			 
			 
    	     return 0;
    	 }
//    	 cprintf("hehe1\n");
    	 le = le->next;
    	 clock_p = clock_p->next;
//    	 cprintf("hehe2\n");
     }

}

static int
_extended_clock_check_swap(void) {
	unsigned char tmp;
	cprintf("write Virt Page e in extended_clock_check_swap\n");
    *(unsigned char *)0x5000 = 0x1e;
	
	
    cprintf("read Virt Page c in extended_clock_check_swap\n");
    tmp = *(unsigned char *)0x3000;
    //cprintf("tmp = 0x%4x\n", tmp);
	
    cprintf("write Virt Page d in extended_clock_check_swap\n");
    *(unsigned char *)0x4000 = 0x0a;

    cprintf("read Virt Page a in extended_clock_check_swap\n");
    tmp = *(unsigned char *)0x1000;
    //cprintf("tmp = 0x%4x\n", tmp);

	
    cprintf("write Virt Page b in extended_clock_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;

    cprintf("write Virt Page e in extended_clock_check_swap\n");
    *(unsigned char *)0x5000 = 0x1e;
	
	cprintf("write Virt Page c in extended_clock_check_swap\n");
    *(unsigned char *)0x3000 = 0x0e;
	
	cprintf("write Virt Page e in extended_clock_check_swap\n");
    *(unsigned char *)0x5000 = 0x2e;
	
	cprintf("read Virt Page c in extended_clock_check_swap\n");
    tmp = *(unsigned char *)0x3000;
	
	cprintf("write Virt Page e in extended_clock_check_swap\n");
    *(unsigned char *)0x5000 = 0x2e;
	//cprintf("--------\n");
	cprintf("write Virt Page a in extended_clock_check_swap\n");
    *(unsigned char *)0x1000 = 0x1a;
	cprintf("write Virt Page a in extended_clock_check_swap\n");
    *(unsigned char *)0x1000 = 0x1a;
    
	//cprintf("--------\n");
    cprintf("read Virt Page b in extended_clock_check_swap\n");
    tmp = *(unsigned char *)0x2000;
    //cprintf("tmp = 0x%4x\n", tmp);
	//cprintf("--------\n");

    cprintf("read Virt Page c in extended_clock_check_swap\n");
    tmp = *(unsigned char *)0x3000;
    //cprintf("tmp = 0x%4x\n", tmp);

    cprintf("read Virt Page d in extended_clock_check_swap\n");
    tmp = *(unsigned char *)0x4000;
    //cprintf("tmp = 0x%4x\n", tmp);

    cprintf("write Virt Page e in extended_clock_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;

    cprintf("read Virt Page a in extended_clock_check_swap\n");
    tmp = *(unsigned char *)0x1000;
    //cprintf("tmp = 0x%4x\n", tmp);

    cprintf("write Virt Page b in extended_clock_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;

    cprintf("write Virt Page e in extended_clock_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;


    return 0;
}


static int
_extended_clock_init(void)
{
    return 0;
}

static int
_extended_clock_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

static int
_extended_clock_tick_event(struct mm_struct *mm)
{ return 0; }


struct swap_manager swap_manager_extended_clock =
{
     .name            = "extended_clock swap manager",
     .init            = &_extended_clock_init,
     .init_mm         = &_extended_clock_init_mm,
     .tick_event      = &_extended_clock_tick_event,
     .map_swappable   = &_extended_clock_map_swappable,
     .set_unswappable = &_extended_clock_set_unswappable,
     .swap_out_victim = &_extended_clock_swap_out_victim,
     .check_swap      = &_extended_clock_check_swap,
};
