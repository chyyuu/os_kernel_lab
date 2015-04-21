#include <stdio.h>

void A();
void B(int a, int b, int c);

int main()
{
	A();
	return 0;
}

void A()
{
	unsigned int a = 1;
	unsigned int b = 2;
	unsigned int c = 3;
	B(a,b,c);
}


void B(int d, int e, int f)
{
	int g;
	unsigned int _ebp;
	__asm__(
		"movl %%ebp,%0\n\t" \
		:"=r" (_ebp));
	g=4;

	printf(" [ebp-12] --?? = %p --- %d \n [ebp-08] --?? = %p --- %d \n [ebp-04] --?? = %p --- %d \n [ebp+00] -oebp= %p --- %p \n [ebp+04] -ret = %p --- %p \n [ebp+08] -- d = %p --- %d \n [ebp+12] -- e = %p --- %d \n [ebp+16] -- f = %p --- %d \n ",
                 (unsigned *)(_ebp-12),  *(unsigned *)(_ebp-12), 
                 (unsigned *)(_ebp-8),  *(unsigned *)(_ebp-8), 
                 (unsigned *)(_ebp-4),  *(unsigned *)(_ebp-4), 
                 (unsigned *)(_ebp),    *(unsigned *)(_ebp),
                 (unsigned *)(_ebp+4),  *(unsigned *)(_ebp+4),
                 (unsigned *)(_ebp+8),  *(unsigned *)(_ebp+8), 
                 (unsigned *)(_ebp+12), *(unsigned *)(_ebp+12), 
                 (unsigned *)(_ebp+16), *(unsigned *)(_ebp+16));

}
