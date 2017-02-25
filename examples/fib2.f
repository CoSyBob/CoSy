| helper function to display size of function
variable mark
macro : mark! here mark ! ; forth
: funcsize last @ >name count type_ here mark @ - . ." bytes" cr ;
| Naive, recursive fib:
mark!
: fib 00; dup 2 <if drop 1 ;; then 1- dup fib swap 1- fib + ; 
funcsize

| If you've ever tried using this, you remember it bogs down a bit after 24
| iterations.  A non-recursive algorithm is faster, though far less interesting
| and elegant:

| newfib.rf
| quicker non-recursive version by rdm cellarguy
mark!
: --bc rot drop ;
: seed -1 1 ;
: fibo 2dup + --bc ;
: fibon ( n>3 -- n ; returns fib of any number >3)
    >r seed fibo r> 0do fibo loop ;
: fib2    ( n -- n ; returns fib of any number up to: 44)
    dup 0 =if drop 0 ;then
    dup 1 =if drop 1 ;then
    dup 2 =if drop 1 ;then
    fibon nip ;
funcsize

| That deals with the slow-down, but doesn't deal with the fact that both
| routines fail after 44 fib, when it overflows the 32bit single-number
| precision.  We can rewrite it in double-number precision like so:

| doublefib.rf

needs math/doubles
with~ ~doubles

mark!
: drot (  a b  c d  e f -- c d  e f  a b )
    4 pick >r 5 pick >r
    >r >r >r >r 2drop
    r> r> r> r> r> r> ;

: d2dup ( a b  cd -- a b  c d  a b  c d )
     2over 2over ;
: dnip ( a b  c d -- c d )
    swap 2 put nip ;
: dseed -1L 1L ;
: dfibo d2dup d+ drot 2drop ;
: dfibon
    >r dseed dfibo r> 0do dfibo loop ;
: fib3    ( n --; displays fib of any number up to: 90)
    dup 0if   drop 0 . ;then
    dup 1 =if drop 1 . ;then
    dup 2 =if drop 1 . ;then
    dup 45 <if 
        fibon nip .
    else     
        dfibon dnip d.
    then ;
funcsize

| Unfortunately, this is only accurate to 90 fib (19 digits).  I wanted to kick
| out numbers as nicely as Haskell's fib routine did, so I wrote the strings
| package and apnea (an arbitrary precision number engine arena) to print out
| numbers of arbitrary size.  This routine uses mvalues and tnumbers:

| refib.rf
0 [IF]
| the "apnea" library is not ready for Reva just yet...
needs apnea

: seed t1 mfree t2 mfree 0 >t1 1 >t2 ;
: nextfib t1 mfree t2 mcount t1 mplace t2 mfree result mcount t2 mplace result mfree ;
: fibob t1 t2 t+ cr t= nextfib fibob ;    | I guess its still recursive.
: fibb seed fibob ;
[THEN]
needs math/big
with~ ~bigmath
big: sum 
big: previous
big: result

mark!
: seed2  -1 previous int>big 1 result int>big ;
| non-recurse:
: fibb2 ( n -- )
	1+
	seed2 0do
		sum result previous big+
		previous result big-copy
		result sum big-copy
	loop
	result .big
	;
funcsize

mark!
2variable sum4
2variable prev4
: seed4 -1L prev4 2! ;
: fib4 ( n -- )
	seed4
	1L rot
	1+ 0do
		2dup prev4 2@ d+ 
		sum4 2dup 2! 2swap
		prev4 2!
	loop
	d.
	;
funcsize
defer thefib
: fibs
	ms@ >r
	0do
		." Fibonacci number " i . ." is " i thefib . cr
	loop
	ms@ r> - cr . ." msec" cr
	;

." fib (recursive, single): " cr ' fib is  thefib 30 fibs
." fib2 (iterative, single): " cr ' fib2 is  thefib 30 fibs

: fibs
	ms@ >r
	0do
		." Fibonacci number " i . ." is " i thefib cr
	loop
	ms@ r> - cr . ." msec" cr
	;

." fib3 (iterative, double): " cr ' fib3 is  thefib 50 fibs
." fib4 (iterative, double): " cr ' fib4 is  thefib 50 fibs
." fibb2 (iterative, bigmath) : " cr ' fibb2 is  thefib 50 fibs

