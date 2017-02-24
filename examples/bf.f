| Implementation of the "Brainfuck" programming language for Reva
| See: http://en.wikipedia.org/wiki/Brainfuck
|
| Commands are:
|   >   increment pointer (move right)
|   <   decrement pointer (move left)
|   +   increment byte at pointer
|   -   decrement byte at pointer
|   .   output value of byte at pointer
|   ,   accept one byte of input, store at pointer
|   [	jump fwd to command after corresponding ], if byte at pointer is zero
|   ]   jump back to command after corresponding [, if byte at pointer is  non-zero

create buf   30000 allot		| classic bf buffer size
variable ptr					| pointer into the buf

| This is the 'brainfuck' interpreter.  Give it a string, and it will 'do its
| thing':

: > ptr ++ ;
: < ptr -- ;
: + ptr dup c@ 1+ swap c! ;
: - ptr dup c@ 1- swap c! ;
: . ptr c@ emit ;
: , key ptr c! ;
: jmp? ptr c@ 0 = ;
macro
: [ p: repeat p: jmp? p: if ;
: ] p: again p: then ;
forth
with~ ~sys
: bf ( a n -- )
	| initialize values:
	buf dup 30000 0 fill ptr !
	| convert the 'bf' code to reva:
	bounds do
		i c@ 1 find-dict if exec else 2drop then
	loop drop
	;
