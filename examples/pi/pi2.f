| http://www.tempest-sw.com/benchmark/
| Tweak from the first port (pi.f) to avoid some variable accesses in favor of stack

variable pi
variable numdigits
variable alength
variable a
variable nines 
variable predigit
variable pilength 

: >pi pi @ pilength @ + c! ;
: >pi2 pi @ pilength @ + + c! ;

0 value Q
: 2-under [ $022e83 3, ;inline
: 10* ( n -- 10*n) [ $c001c389 , $0103e3c1 , $d8 1, ;inline
: computepi 
	| allocate work area:
	numdigits @ 10 3 */ dup alength ! cells allocate dup a ! 
	| initialize work area to '2'
	alength @ 0 do 2 over ! cell+ loop  drop
	| main loop
	0 to Q
	numdigits @ 0 do
		alength @ 2* 1-  
		Q alength @ 0 do 
			remains swap over 1+ * swap
			cells a @ + dup >r
			@ 10* +	
			over /mod swap
			r> !  2-under
		loop 
		nip dup to Q 

		| a[0] = q % 10
		| q /= 10
		10 /mod to Q a @ !
		Q dup 9 =if nines ++ drop else
			predigit @
			swap
			10 =if
				1+ 
				'0 + >pi
				nines @ 1+ 1 do '0 i >pi2 loop
				predigit off
			else
				'0 + >pi
				Q predigit !
				nines @ 1+ 1 do '9 i >pi2 loop
			then
			nines @ 1+ pilength +!
			nines off
		then
	loop
	predigit @ '0 + >pi
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
