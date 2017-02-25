: b-fib 40 fib drop ;
: b-do 1000 dltest ;
: b-smr 500sines ;

variable fun
: test
	fun !
	3 0 do
	ms@ >r 
		fun @ execute
	ms@ r> - .ms
	loop cr ;
: bench
	cr
	ms@ >r 
		." recursive fib: " ['] b-fib test
		." noop do-loop:  " ['] b-do test
	ms@	r@ - ." Old bench:   " .ms cr
		." 500sine sum:   " ['] b-smr test
	ms@	r> - ." Total time:  " .ms cr
	;
