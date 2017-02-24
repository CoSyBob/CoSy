| dump words in Reva, with their address, class and context:
with~ ~priv
here variable, starthere | don't list the words we create here!
needs util/classes
needs alg/hsort
needs string/justify

variable curctx
variable dictlist# 
create dictlist 10000 cells allot
: buildlist
	{
		@ dup curctx !
		@ | 'last' for this context
		{
			cell- 
				dup >xt @ starthere @ <if
					here swap
					, curctx @ ,		| +00=dict, +04=ctx
					dictlist# @			| dict cnt
					cells dictlist + !	| 
					dictlist# ++
				else
					drop
				then
			true
		} swap iterate
		true
	} all-contexts iterate
	;

:: ( a1 a2 -- f )	@ cell+ @ swap @ cell+ @ > ; is compare
: sortlist dictlist dictlist# @ hsort ;

: map  ( ptr -- )
	>r
	r@ @ | dict
	dup >xt @ .x 
	dup .x
	classof 10 ljust space
	r@ cell+ @ ctx>name 12 ljust space 
	r> @ >name count 
		dup 0if 2drop ." :: " else type  then
		cr
	;

: showlist
	." address  dictptr  class      context      name" cr
	dictlist# @ 0do
		dictlist i cells + @ map
	loop
	cr
	;

buildlist sortlist showlist bye
