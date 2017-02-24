\ benchmark code for VFX Forth
: 3. s>d <# # # # #> type ;
: (.) s>d <# #s #> ;
: ms@ GetTickCount ;
: .ms 1000 /mod (.) type [char] . emit 3. space ;

: fib ( x -- y )
	dup 2 > if 1- dup recurse
		swap 1- recurse + exit
	then drop 1 ;
: smr 0e0 5001 1 do i s>f fsin f+ loop ;
19 set-precision cr ." smr (.27970133224749172): " smr f. cr
: 500sines 10000 1 do smr fdrop loop ;
: dl 100000 0 do noop loop ; : dltest 0 do dl loop ;
include bench-common.f
bench
