needs os/threads

1 [IF]
0 value A
0 value B

." Thread test:" cr
variable count
: a count !
: aa count ++ 5 ms 
	count @ 1600 >if ." a exiting" cr exitthread ;then
	aa ;

variable lastcount
: b . 
: bb count ? 100 ms 
	count @ lastcount 2dup @ =if 500 ms ." b exiting" cr exitthread ;then
	!
	bb ;

' a 1234 100 thread to A
' b 5234 100 thread to B

A waitthread ." A is done" cr
B waitthread ." B is done" cr
[THEN]

cr ." Mutex test:" cr 
variable m
m mutex
0 value T1
0 value T2
0 value T3
0 value done
: t m lockmutex done if m unlockmutex ;then dup emit  m unlockmutex 5 ms t ;

: t3 1000 ms m lockmutex cr ." Killing threads" cr 
	true to done
	m unlockmutex
	;

' t 'A 20 thread to T1
' t 'B 20 thread to T2
' t3 0 20 thread to T3

T3 waitthread 
m closemutex
." Done!" cr

bye
