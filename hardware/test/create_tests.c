#include <stdio.h>

int main()
{
	for(int i=0; i < 100; i++)
	{
		float ia = (float)i + 0.25f;
		float ib = (float)i + 0.5f;
		int c;
		float ic;
		
		int a = *((int *) &ia );
		int b = *((int *) &ib );
		
		printf("%x\n", a);
		printf("%x\n", b);
		ic = ia + ib;		
		c = *((int *) &ic );
		printf("add\t%x\t", c);
		ic = ia - ib;		
		c = *((int *) &ic );
		printf("sub\t%x\t", c);
		ic = ia * ib;		
		c = *((int *) &ic );
		printf("mul\t%x\t", c);
		ic = ia / ib;		
		c = *((int *) &ic );
		printf("div\t%x\t", c);
		printf("\n");
	}
}