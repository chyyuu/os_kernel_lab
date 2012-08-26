#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <assert.h>
#include <kmalloc.h>
#include <sync.h>
#include <pmm.h>
#include <stdio.h>
#include <rb_tree.h>

/* The slab allocator used in ucore is based on an algorithm first introduced by 
   Jeff Bonwick for the SunOS operating system. The paper can be download from 
   http://citeseer.ist.psu.edu/bonwick94slab.html 
   An implementation of the Slab Allocator as described in outline in;
      UNIX Internals: The New Frontiers by Uresh Vahalia
      Pub: Prentice Hall      ISBN 0-13-101908-2
   Within a kernel, a considerable amount of memory is allocated for a finite set 
   of objects such as file descriptors and other common structures. Jeff found that
   the amount of time required to initialize a regular object in the kernel exceeded
   the amount of time required to allocate and deallocate it. His conclusion was 
   that instead of freeing the memory back to a global pool, he would have the memory
   remain initialized for its intended purpose.
   In our simple slab implementation, the the high-level organization of the slab 
   structures is simplied. At the highest level is an array slab_cache[SLAB_CACHE_NUM],
   and each array element is a slab_cache which has slab chains. Each slab_cache has 
   two list, one list chains the full allocated slab, and another list chains the notfull 
   allocated(maybe empty) slab.  And  each slab has fixed number(2^n) of pages. In each 
   slab, there are a lot of objects (such as ) with same fixed size(32B ~ 128KB). 
   
   +----------------------------------+
   | slab_cache[0] for 0~32B obj      |
   +----------------------------------+
   | slab_cache[1] for 33B~64B obj    |-->lists for slabs
   +----------------------------------+            |  
   | slab_cache[2] for 65B~128B obj   |            |            
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~            |                 
   +----------------------------------+            |
   | slab_cache[12]for 64KB~128KB obj |            |                    
   +----------------------------------+            |
                                                   |
     slabs_full/slabs_not    +---------------------+
   -<-----------<----------<-+
   |           |         |
  slab1       slab2     slab3...
   |
   |-------|-------|
  pages1  pages2   pages3...
   |
   |
   |
   slab_t+n*bufctl_t+obj1-obj2-obj3...objn  (the size of obj is small)
   |
   OR
   |
   obj1-obj2-obj3...objn  WITH slab_t+n*bufctl_t in another slab (the size of obj is BIG)

   The important functions are:
     kmem_cache_grow(kmem_cache_t *cachep)
     kmem_slab_destroy(kmem_cache_t *cachep, slab_t *slabp)
     kmalloc(size_t size): used by outside functions need dynamicly get memory
     kfree(void *objp): used by outside functions need dynamicly release memory
*/
  
#define BUFCTL_END      0xFFFFFFFFL // the signature of the last bufctl
#define SLAB_LIMIT      0xFFFFFFFEL // the max value of obj number

typedef size_t kmem_bufctl_t; //the index of obj in slab

typedef struct slab_s {
    list_entry_t slab_link; // the list entry linked to kmem_cache list
    void *s_mem;            // the kernel virtual address of the first obj in slab 
    size_t inuse;           // the number of allocated objs
    size_t offset;          // the first obj's offset value in slab
    kmem_bufctl_t free;     // the first free obj's index in slab  
} slab_t;

// get the slab address according to the link element (see list.h)
#define le2slab(le, member)                 \
    to_struct((le), slab_t, member)

typedef struct kmem_cache_s kmem_cache_t;


struct kmem_cache_s {
    list_entry_t slabs_full;     // list for fully allocated slabs
    list_entry_t slabs_notfull;  // list for not-fully allocated slabs

    size_t objsize;              // the fixed size of obj
    size_t num;                  // number of objs per slab
    size_t offset;               // this first obj's offset in slab 
    bool off_slab;               // the control part of slab in slab or not.

    /* order of pages per slab (2^n) */
    size_t page_order;

    kmem_cache_t *slab_cachep;
};

#define MIN_SIZE_ORDER          5           // 32
#define MAX_SIZE_ORDER          17          // 128k
#define SLAB_CACHE_NUM          (MAX_SIZE_ORDER - MIN_SIZE_ORDER + 1)

static kmem_cache_t slab_cache[SLAB_CACHE_NUM];

static void init_kmem_cache(kmem_cache_t *cachep, size_t objsize, size_t align);
static void check_slab(void);


//slab_init - call init_kmem_cache function to reset the slab_cache array
static void
slab_init(void) {
    size_t i;
    //the align bit for obj in slab. 2^n could be better for performance
    size_t align = 16;
    for (i = 0; i < SLAB_CACHE_NUM; i ++) {
        init_kmem_cache(slab_cache + i, 1 << (i + MIN_SIZE_ORDER), align);
    }
    check_slab();
}

inline void 
kmalloc_init(void) {
    slab_init();
    cprintf("kmalloc_init() succeeded!\n");
}

//slab_allocated - summary the total size of allocated objs
static size_t
slab_allocated(void) {
    size_t total = 0;
    int i;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        for (i = 0; i < SLAB_CACHE_NUM; i ++) {
            kmem_cache_t *cachep = slab_cache + i;
            list_entry_t *list, *le;
            list = le = &(cachep->slabs_full);
            while ((le = list_next(le)) != list) {
                total += cachep->num * cachep->objsize;
            }
            list = le = &(cachep->slabs_notfull);
            while ((le = list_next(le)) != list) {
                slab_t *slabp = le2slab(le, slab_link);
                total += slabp->inuse * cachep->objsize;
            }
        }
    }
    local_intr_restore(intr_flag);
    return total;
}

// slab_mgmt_size - get the size of slab control area (slab_t+num*kmem_bufctl_t)
static size_t
slab_mgmt_size(size_t num, size_t align) {
    return ROUNDUP(sizeof(slab_t) + num * sizeof(kmem_bufctl_t), align);
}

// cacahe_estimate - estimate the number of objs in a slab
static void
cache_estimate(size_t order, size_t objsize, size_t align, bool off_slab, size_t *remainder, size_t *num) {
    size_t nr_objs, mgmt_size;
    size_t slab_size = (PGSIZE << order);

    if (off_slab) {
        mgmt_size = 0;
        nr_objs = slab_size / objsize;
        if (nr_objs > SLAB_LIMIT) {
            nr_objs = SLAB_LIMIT;
        }
    }
    else {
        nr_objs = (slab_size - sizeof(slab_t)) / (objsize + sizeof(kmem_bufctl_t));
        while (slab_mgmt_size(nr_objs, align) + nr_objs * objsize > slab_size) {
            nr_objs --;
        }
        if (nr_objs > SLAB_LIMIT) {
            nr_objs = SLAB_LIMIT;
        }
        mgmt_size = slab_mgmt_size(nr_objs, align);
    }
    *num = nr_objs;
    *remainder = slab_size - nr_objs * objsize - mgmt_size;
}

// calculate_slab_order - estimate the size(4K~4M) of slab
// paramemters:
//   cachep:    the slab_cache
//   objsize:   the size of obj
//   align:     align bit for objs
//   off_slab:  the control part of slab in slab or not
//   left_over: the size of can not be used area in slab
static void
calculate_slab_order(kmem_cache_t *cachep, size_t objsize, size_t align, bool off_slab, size_t *left_over) {
    size_t order;
    for (order = 0; order <= KMALLOC_MAX_ORDER; order ++) {
        size_t num, remainder;
        cache_estimate(order, objsize, align, off_slab, &remainder, &num);
        if (num != 0) {
            if (off_slab) {
                size_t off_slab_limit = objsize - sizeof(slab_t);
                off_slab_limit /= sizeof(kmem_bufctl_t);
                if (num > off_slab_limit) {
                    panic("off_slab: objsize = %d, num = %d.", objsize, num);
                }
            }
            if (remainder * 8 <= (PGSIZE << order)) {
                cachep->num = num;
                cachep->page_order = order;
                if (left_over != NULL) {
                    *left_over = remainder;
                }
                return ;
            }
        }
    }
    panic("calculate_slab_over: failed.");
}

// getorder - find order, should satisfy n <= minest 2^order
static inline size_t
getorder(size_t n) {
    size_t order = MIN_SIZE_ORDER, order_size = (1 << order);
    for (; order <= MAX_SIZE_ORDER; order ++, order_size <<= 1) {
        if (n <= order_size) {
            return order;
        }
    }
    panic("getorder failed. %d\n", n);
}

// init_kmem_cache - initial a slab_cache cachep according to the obj with the size = objsize
static void
init_kmem_cache(kmem_cache_t *cachep, size_t objsize, size_t align) {
    list_init(&(cachep->slabs_full));
    list_init(&(cachep->slabs_notfull));

    objsize = ROUNDUP(objsize, align);
    cachep->objsize = objsize;
    cachep->off_slab = (objsize >= (PGSIZE >> 3));

    size_t left_over;
    calculate_slab_order(cachep, objsize, align, cachep->off_slab, &left_over);

    assert(cachep->num > 0);

    size_t mgmt_size = slab_mgmt_size(cachep->num, align);

    if (cachep->off_slab && left_over >= mgmt_size) {
        cachep->off_slab = 0;
    }

    if (cachep->off_slab) {
        cachep->offset = 0;
        cachep->slab_cachep = slab_cache + (getorder(mgmt_size) - MIN_SIZE_ORDER);
    }
    else {
        cachep->offset = mgmt_size;
    }
}

static void *kmem_cache_alloc(kmem_cache_t *cachep);

#define slab_bufctl(slabp)              \
    ((kmem_bufctl_t*)(((slab_t *)(slabp)) + 1))

// kmem_cache_slabmgmt - get the address of a slab according to page
//                     - and initialize the slab according to cachep
static slab_t *
kmem_cache_slabmgmt(kmem_cache_t *cachep, struct Page *page) {
    void *objp = page2kva(page);
    slab_t *slabp;
    if (cachep->off_slab) {
        if ((slabp = kmem_cache_alloc(cachep->slab_cachep)) == NULL) {
            return NULL;
        }
    }
    else {
        slabp = page2kva(page);
    }
    slabp->inuse = 0;
    slabp->offset = cachep->offset;
    slabp->s_mem = objp + cachep->offset;
    return slabp;
}

#define SET_PAGE_CACHE(page, cachep)                                                \
    do {                                                                            \
        struct Page *__page = (struct Page *)(page);                                \
        kmem_cache_t **__cachepp = (kmem_cache_t **)&(__page->page_link.next);      \
        *__cachepp = (kmem_cache_t *)(cachep);                                      \
    } while (0)

#define SET_PAGE_SLAB(page, slabp)                                                  \
    do {                                                                            \
        struct Page *__page = (struct Page *)(page);                                \
        slab_t **__cachepp = (slab_t **)&(__page->page_link.prev);                  \
        *__cachepp = (slab_t *)(slabp);                                             \
    } while (0)

// kmem_cache_grow - allocate a new slab by calling alloc_pages
//                 - set control area in the new slab
static bool
kmem_cache_grow(kmem_cache_t *cachep) {
    struct Page *page = alloc_pages(1 << cachep->page_order);
    if (page == NULL) {
        goto failed;
    }

    slab_t *slabp;
    if ((slabp = kmem_cache_slabmgmt(cachep, page)) == NULL) {
        goto oops;
    }

    size_t order_size = (1 << cachep->page_order);
    do {
        //setup this page in the free list (see memlayout.h: struct page)???
        SET_PAGE_CACHE(page, cachep);
        SET_PAGE_SLAB(page, slabp);
    //this page is used for slab
        SetPageSlab(page);
        page ++;
    } while (-- order_size);

    int i;
    for (i = 0; i < cachep->num; i ++) {
        slab_bufctl(slabp)[i] = i + 1;
    }
    slab_bufctl(slabp)[cachep->num - 1] = BUFCTL_END;
    slabp->free = 0;

    bool intr_flag;
    local_intr_save(intr_flag);
    {
        list_add(&(cachep->slabs_notfull), &(slabp->slab_link));
    }
    local_intr_restore(intr_flag);
    return 1;

oops:
    free_pages(page, 1 << cachep->page_order);
failed:
    return 0;
}

// kmem_cache_alloc_one - allocate a obj in a slab
static void * 
kmem_cache_alloc_one(kmem_cache_t *cachep, slab_t *slabp) {
    slabp->inuse ++;
    void *objp = slabp->s_mem + slabp->free * cachep->objsize;
    slabp->free = slab_bufctl(slabp)[slabp->free];

    if (slabp->free == BUFCTL_END) {
        list_del(&(slabp->slab_link));
        list_add(&(cachep->slabs_full), &(slabp->slab_link));
    }
    return objp;
}

// kmem_cache_alloc - call kmem_cache_alloc_one function to allocate a obj
//                  - if no free obj, try to allocate a slab
static void *
kmem_cache_alloc(kmem_cache_t *cachep) {
    void *objp;
    bool intr_flag;

try_again:
    local_intr_save(intr_flag);
    if (list_empty(&(cachep->slabs_notfull))) {
        goto alloc_new_slab;
    }
    slab_t *slabp = le2slab(list_next(&(cachep->slabs_notfull)), slab_link);
    objp = kmem_cache_alloc_one(cachep, slabp);
    local_intr_restore(intr_flag);
    return objp;

alloc_new_slab:
    local_intr_restore(intr_flag);

    if (kmem_cache_grow(cachep)) {
        goto try_again;
    }
    return NULL;
}

// kmalloc - simple interface used by outside functions 
//         - to allocate a free memory using kmem_cache_alloc function
void *
kmalloc(size_t size) {
    assert(size > 0);
    size_t order = getorder(size);
    if (order > MAX_SIZE_ORDER) {
        return NULL;
    }
    return kmem_cache_alloc(slab_cache + (order - MIN_SIZE_ORDER));
}

static void kmem_cache_free(kmem_cache_t *cachep, void *obj);

// kmem_slab_destroy - call free_pages & kmem_cache_free to free a slab 
static void
kmem_slab_destroy(kmem_cache_t *cachep, slab_t *slabp) {
    struct Page *page = kva2page(slabp->s_mem - slabp->offset);

    struct Page *p = page;
    size_t order_size = (1 << cachep->page_order);
    do {
        assert(PageSlab(p));
        ClearPageSlab(p);
        p ++;
    } while (-- order_size);

    free_pages(page, 1 << cachep->page_order);

    if (cachep->off_slab) {
        kmem_cache_free(cachep->slab_cachep, slabp);
    }
}

// kmem_cache_free_one - free an obj in a slab
//                     - if slab->inuse==0, then free the slab
static void
kmem_cache_free_one(kmem_cache_t *cachep, slab_t *slabp, void *objp) {
    //should not use divide operator ???
    size_t objnr = (objp - slabp->s_mem) / cachep->objsize;
    slab_bufctl(slabp)[objnr] = slabp->free;
    slabp->free = objnr;

    slabp->inuse --;

    if (slabp->inuse == 0) {
        list_del(&(slabp->slab_link));
        kmem_slab_destroy(cachep, slabp);
    }
    else if (slabp->inuse == cachep->num -1 ) {
        list_del(&(slabp->slab_link));
        list_add(&(cachep->slabs_notfull), &(slabp->slab_link));
    }
}

#define GET_PAGE_CACHE(page)                                \
    (kmem_cache_t *)((page)->page_link.next)

#define GET_PAGE_SLAB(page)                                 \
    (slab_t *)((page)->page_link.prev)

// kmem_cache_free - call kmem_cache_free_one function to free an obj 
static void
kmem_cache_free(kmem_cache_t *cachep, void *objp) {
    bool intr_flag;
    struct Page *page = kva2page(objp);

    if (!PageSlab(page)) {
        panic("not a slab page %08x\n", objp);
    }
    local_intr_save(intr_flag);
    {
        kmem_cache_free_one(cachep, GET_PAGE_SLAB(page), objp);
    }
    local_intr_restore(intr_flag);
}

// kfree - simple interface used by ooutside functions to free an obj
void
kfree(void *objp) {
    kmem_cache_free(GET_PAGE_CACHE(kva2page(objp)), objp);
}

static inline void
check_slab_empty(void) {
    int i;
    for (i = 0; i < SLAB_CACHE_NUM; i ++) {
        kmem_cache_t *cachep = slab_cache + i;
        assert(list_empty(&(cachep->slabs_full)));
        assert(list_empty(&(cachep->slabs_notfull)));
    }
}

void
check_slab(void) {
    int i;
    void *v0, *v1;

    size_t nr_free_pages_store = nr_free_pages();
    size_t kernel_allocated_store = slab_allocated();

    /* slab must be empty now */
    check_slab_empty();
    assert(slab_allocated() == 0);

    kmem_cache_t *cachep0, *cachep1;

    cachep0 = slab_cache;
    assert(cachep0->objsize == 32 && cachep0->num > 1 && !cachep0->off_slab);
    assert((v0 = kmalloc(16)) != NULL);

    slab_t *slabp0, *slabp1;

    assert(!list_empty(&(cachep0->slabs_notfull)));
    slabp0 = le2slab(list_next(&(cachep0->slabs_notfull)), slab_link);
    assert(slabp0->inuse == 1 && list_next(&(slabp0->slab_link)) == &(cachep0->slabs_notfull));

    struct Page *p0, *p1;
    size_t order_size;


    p0 = kva2page(slabp0->s_mem - slabp0->offset), p1 = p0;
    order_size = (1 << cachep0->page_order);
    for (i = 0; i < cachep0->page_order; i ++, p1 ++) {
        assert(PageSlab(p1));
        assert(GET_PAGE_CACHE(p1) == cachep0 && GET_PAGE_SLAB(p1) == slabp0);
    }

    assert(v0 == slabp0->s_mem);
    assert((v1 = kmalloc(16)) != NULL && v1 == v0 + 32);

    kfree(v0);
    assert(slabp0->free == 0);
    kfree(v1);
    assert(list_empty(&(cachep0->slabs_notfull)));

    for (i = 0; i < cachep0->page_order; i ++, p0 ++) {
        assert(!PageSlab(p0));
    }


    v0 = kmalloc(16);
    assert(!list_empty(&(cachep0->slabs_notfull)));
    slabp0 = le2slab(list_next(&(cachep0->slabs_notfull)), slab_link);

    for (i = 0; i < cachep0->num - 1; i ++) {
        kmalloc(16);
    }

    assert(slabp0->inuse == cachep0->num);
    assert(list_next(&(cachep0->slabs_full)) == &(slabp0->slab_link));
    assert(list_empty(&(cachep0->slabs_notfull)));

    v1 = kmalloc(16);
    assert(!list_empty(&(cachep0->slabs_notfull)));
    slabp1 = le2slab(list_next(&(cachep0->slabs_notfull)), slab_link);

    kfree(v0);
    assert(list_empty(&(cachep0->slabs_full)));
    assert(list_next(&(slabp0->slab_link)) == &(slabp1->slab_link)
            || list_next(&(slabp1->slab_link)) == &(slabp0->slab_link));

    kfree(v1);
    assert(!list_empty(&(cachep0->slabs_notfull)));
    assert(list_next(&(cachep0->slabs_notfull)) == &(slabp0->slab_link));
    assert(list_next(&(slabp0->slab_link)) == &(cachep0->slabs_notfull));

    v1 = kmalloc(16);
    assert(v1 == v0);
    assert(list_next(&(cachep0->slabs_full)) == &(slabp0->slab_link));
    assert(list_empty(&(cachep0->slabs_notfull)));

    for (i = 0; i < cachep0->num; i ++) {
        kfree(v1 + i * cachep0->objsize);
    }

    assert(list_empty(&(cachep0->slabs_full)));
    assert(list_empty(&(cachep0->slabs_notfull)));

    cachep0 = slab_cache;

    bool has_off_slab = 0;
    for (i = 0; i < SLAB_CACHE_NUM; i ++, cachep0 ++) {
        if (cachep0->off_slab) {
            has_off_slab = 1;
            cachep1 = cachep0->slab_cachep;
            if (!cachep1->off_slab) {
                break;
            }
        }
    }

    if (!has_off_slab) {
        goto check_pass;
    }

    assert(cachep0->off_slab && !cachep1->off_slab);
    assert(cachep1 < cachep0);

    assert(list_empty(&(cachep0->slabs_full)));
    assert(list_empty(&(cachep0->slabs_notfull)));

    assert(list_empty(&(cachep1->slabs_full)));
    assert(list_empty(&(cachep1->slabs_notfull)));

    v0 = kmalloc(cachep0->objsize);
    p0 = kva2page(v0);
    assert(page2kva(p0) == v0);

    if (cachep0->num == 1) {
        assert(!list_empty(&(cachep0->slabs_full)));
        slabp0 = le2slab(list_next(&(cachep0->slabs_full)), slab_link);
    }
    else {
        assert(!list_empty(&(cachep0->slabs_notfull)));
        slabp0 = le2slab(list_next(&(cachep0->slabs_notfull)), slab_link);
    }

    assert(slabp0 != NULL);

    if (cachep1->num == 1) {
        assert(!list_empty(&(cachep1->slabs_full)));
        slabp1 = le2slab(list_next(&(cachep1->slabs_full)), slab_link);
    }
    else {
        assert(!list_empty(&(cachep1->slabs_notfull)));
        slabp1 = le2slab(list_next(&(cachep1->slabs_notfull)), slab_link);
    }

    assert(slabp1 != NULL);

    order_size = (1 << cachep0->page_order);
    for (i = 0; i < order_size; i ++, p0 ++) {
        assert(PageSlab(p0));
        assert(GET_PAGE_CACHE(p0) == cachep0 && GET_PAGE_SLAB(p0) == slabp0);
    }

    kfree(v0);

check_pass:

    check_rb_tree();
    check_slab_empty();
    assert(slab_allocated() == 0);
    assert(nr_free_pages_store == nr_free_pages());
    assert(kernel_allocated_store == slab_allocated());

    cprintf("check_slab() succeeded!\n");
}

