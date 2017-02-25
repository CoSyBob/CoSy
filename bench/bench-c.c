#include <stdio.h>
#include <time.h>

int fib ( int n )
{
	if (n>2)
		return (fib(n-1) + fib(n-2));
	else
		return 1;
}

void fibtest(void)
{
	fib(40);
}

void printms(int n)
{
	printf("%d.%03d ", n/1000, n%1000);
}

int ms()
{
	return clock();
}

void timeit( void (*f)() )
{
	int t1 = ms();
	f();
	printms(ms()-t1);
}

void noop()
{
}
void nooploop()
{
	int ix;
	int ix2;
	for (ix=0; ix<1000; ix++)
	{
		for (ix2=0; ix2<100000; ix2++)
			noop();
	}
}

int main ( void )
{
	int t1;
	t1 = ms();
	printf("recursive fib: ");
	timeit(fibtest);
	timeit(fibtest);
	timeit(fibtest);
	printf("\n");
	printf("noop loop: ");
	timeit(nooploop);
	timeit(nooploop);
	timeit(nooploop);
	printf("\n");

	printf("Total: ");
	printms(ms()-t1);
	return 0;
}
