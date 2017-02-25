| Alt stack ops 
| Self explanatory .
| Author: Bob Armstrong / www.CoSy.com
| Reva's license terms also apply to this file.

." | AllStackOps begin | "

context: ~AltStackOps ~AltStackOps 

alias: --aa       dup
alias: a--        drop
alias: --ba       swap
alias: --aba      over
alias: --b        nip
alias: --bab      tuck
alias: --bca      rot
alias: --c		  _2nip
alias: --cab      -rot

alias: --abab    2dup
alias: ab--      2drop
alias: --cd		 2nip
alias: --cdab    2swap
alias: --abcdab  2over
alias: --abcabc  3dup
alias: --abcdabcd	4dup

alias: --ababc	_2dup		| Ron's def ( >r 2dup r> ) .

|		can't be inlined , caused bugs !
: --aaa		dup dup ;
: --aab		over swap ;
: --aaba    over swap over ;
: --aabc	2 pick -rot ;	| better than Danny's | >r >r dup r> r> swap 
: --aacb	--aabc swap ;
: --abaa 	over dup ;
: --abba 	2dup swap ;
: --abca	2 pick ;
: --abac	2 pick swap ;
: --acab	2 pick rot ;
: --abcda	3 pick ;
: --abcab	2 pick 2 pick ;
: --bab		dup -rot ;
: --bba		tuck swap ;		| or | dup rot 
: --bc		rot drop ;

: --c		nip nip ;
| : --ca 		-rot drop ; 	| For some reason defining this name causes IUP to bomb on any execute ? 
: --cba		swap rot ;

: underswap  ( a b c -- b a c )	| cellarguy 	
   inline{  8B 5E 04 8B 0E 89 1E 89 4E 04 } ;
alias: --bac underswap 	| http://ronware.org/reva/viewtopic.php?pid=4487#p4487

: --dceab	>r swap 2swap r> -rot ;	| permutation used by Ron in string/misc tr

exit~ with~ ~AltStackOps

." | AllStackOps end | " cr
