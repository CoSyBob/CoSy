| http://www.tempest-sw.com/benchmark/
| Direct port from the C code

variable pi
variable numdigits
variable alength
variable a
variable pilength 
variable nines 
variable predigit
variable Q
variable P

: computepi 
	| allocate work area:
	numdigits @ 10 3 */ dup alength ! cells allocate dup a ! 
	| initialize work area to '2'
	alength @ 0 do 2 over ! cell+ loop  drop
	| main loop
	numdigits @ 0 do
		Q off
        | int p = 2 * alength - 1;
		alength @ 2* 1- P !
		| downto loop:
		alength @ 0 do 
			| x = 10*a[i] + q*(i+1)
			remains dup 1+ | i i+1
			Q @ * swap | q*(i+1) i
			cells a @ + dup >r @ | q*(i+1) a[i]  
			10 * + | x ( r:a+i)
			| a[i] = x%p
			dup P @ mod | x x*p
			r> !  | a[i] = x*p
			| q = x / p
			P @ / Q !
			| p -= 2
			P -- P --
		loop

		| a[0] = q % 10
		| q /= 10
		Q @ 10 /mod Q ! a @ !
		Q @ 9 =if 
			nines ++ 
		else
			Q @ 10 =if
|				pi[piLength] = (char) (predigit + 1 + '0');
				predigit @ 1+ '0 + pi @ pilength @ + c!  
|				for (k = 1; k <= nines; ++k)
|					pi[piLength+k] = '0';
				nines @ 1+ 1 do
					'0 pi @ pilength @ + i + c!
				loop
|				predigit = 0;
				predigit off
			else
|				pi[piLength] = (char)(predigit + '0');
				predigit @ '0 + pi @ pilength @ + c!  
|				predigit = q;
				Q @ predigit !
|				for (k = 1; k <= nines; ++k)
|					pi[piLength + k] = '9';
				nines @ 1+ 1 do
					'9 pi @ pilength @ i + + c!
				loop
			then
|			piLength += nines + 1;
			nines @ 1+ pilength +!
|			nines = 0;
			nines off
		then
	loop
    | pi[piLength] = (char)(predigit + '0');
	predigit @ '0 + 
	pilength @ pi @ + c! 
	;
: setup
	argc 3 <>if ." usage: pi #DIGITS" cr bye then
	2 argv >single 0if ." #DIGITS must be a number!" cr bye then
	dup numdigits !
	1+ allocate pi !
	;
: printpi pi @ numdigits @ type cr ;
: cleanup pi @ free a @ free ;
setup computepi printpi cleanup bye
