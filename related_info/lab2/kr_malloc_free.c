#include <stdio.h>

//K&R Chapt5, Section   4
#if 0
#define ALLOCSIZE 10000
static char allocbuf[ALLOCSIZE];    /*storage for alloc*/
static char *allocp = allocbuf;    /*next free position*/

char *alloc(int n)
{
    if(allocbuf+ALLOCSIZE - allocp >= n) {
        allocp += n;
        return alloc - n;
    } else
        return 0;
}

void afree(char *p)
{
    if (p >= allocbuf && p<allocbuf + ALLOCSIZE)
        allocp = p;
}
#endif


//K&R Chapt8, Section 7
#define NULL 0
typedef long Align;/*for alignment to long boundary*/
union header {
    struct {
        union header *ptr; /*next block if on free list*/
        unsigned size; /*size of this block*/
    } s;
    Align x;
};

typedef union header Header;


static Header base;
static Header *freep = NULL;



void kr_free(void *ap)
{
    Header *bp,*p;
    bp = (Header *)ap -1; /* point to block header */
    printf("kr_free: bp 0x%x, size %d\n",bp,bp->s.size);
    for(p=freep;!(bp>p && bp< p->s.ptr);p=p->s.ptr)
        if(p>=p->s.ptr && (bp>p || bp<p->s.ptr))
            break;    /* freed block at start or end of arena*/
    if (bp+bp->s.size==p->s.ptr) {    /* join to upper nbr */
        bp->s.size += p->s.ptr->s.size;
        bp->s.ptr = p->s.ptr->s.ptr;
    } else
        bp->s.ptr = p->s.ptr;
    if (p+p->s.size == bp) {     /* join to lower nbr */
        p->s.size += bp->s.size;
        p->s.ptr = bp->s.ptr;
    } else
        p->s.ptr = bp;
    freep = p;
}


#define NALLOC 1024    /* minimum #units to request */
static Header *morecore(unsigned nu)
{
    char *cp;
    Header *up;
    if(nu < NALLOC)
        nu = NALLOC;

    cp = sbrk(nu * sizeof(Header));
    printf("morecore: cp 0x%x, size %d\n",cp,nu * sizeof(Header));
    if(cp == (char *)-1)    /* no space at all*/
        return NULL;
    up = (Header *)cp;
    up->s.size = nu;
    kr_free((void *)(up+1));
    return freep;
}


void *kr_malloc(unsigned nbytes)
{
    Header *p, *prevp;
    unsigned nunits;
    nunits = (nbytes+sizeof(Header)-1)/sizeof(Header) + 1;
   printf("kr_malloc: nbytes %d, nunits %d\n",nbytes,nunits);    
    if((prevp = freep) == NULL) { /* no free list */
        base.s.ptr = freep = prevp = &base;
        base.s.size = 0;
    }
    for(p = prevp->s.ptr; ;prevp = p, p= p->s.ptr) {
        if(p->s.size >= nunits) { /* big enough */
            if (p->s.size == nunits)  /* exactly */
                prevp->s.ptr = p->s.ptr;
            else {
                p->s.size -= nunits;
                p += p->s.size;
                p->s.size = nunits;
            }
            freep = prevp;
            printf("kr_malloc: p 0x%x, size %d\n",p,p->s.size);
            return (void*)(p+1);
        }
        if (p== freep) /* wrapped around free list */
            if ((p = morecore(nunits)) == NULL) {
                printf("kr_malloc: no free space!!!\n");
                return NULL; /* none left */
            }
    }
}


void kr_dump(void)
{ static int i=0;
    Header *p, *prevp;
	prevp = freep;
	i++;
	for(p = prevp->s.ptr; ;prevp = p, p= p->s.ptr) {
		if(p== freep) {
		 	return;
		}
		printf("kr_dump: %d: p 0x%x, size %d\n", i, p, p->s.size);

	}
}

void main(void)
{
   void * na,*nb,*nc,*nd,*ne, *nf;
   printf("size of Header  is %d\n", sizeof(Header));
   na=kr_malloc(16);
   kr_dump();
   kr_free(na);
   kr_dump();
   nb=kr_malloc(48);
   kr_dump();
   nc=kr_malloc(60);
   kr_dump();
   nd=kr_malloc(128);
   kr_dump();
   kr_free(nb);
   kr_dump();
   ne=kr_malloc(512);
   kr_dump();
   kr_free(nd);
   kr_dump();
   nf=kr_malloc(256);
   kr_dump();
   kr_free(nc);
   kr_dump();
   kr_free(nf);
   kr_dump();
   kr_free(ne);
   kr_dump();
}
