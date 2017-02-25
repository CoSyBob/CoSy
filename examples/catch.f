| throw and catch

variable ex

: blab type cr ;
: except " got exception" blab bye ;
: a " in a" blab 
	ex @ 1+ dup ex ! throw ;
: b " in b" blab 
	['] a catch if ." b " except then
	" after a " blab ;
: c " in c" blab 
	['] b catch if ." c " except then 
	" after b " blab ;

c bye
