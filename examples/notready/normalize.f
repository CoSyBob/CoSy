| normalize hebrew (utf8)

needs string/iconv

variable outh
variable inptr
variable outptr

2variable inbuf
2variable outbuf

z" ucs-2" z" utf-8" iconv_open constant >uni
z" utf-8" z" ucs-2" iconv_open constant uni>

create outfilename 512 allot | output file name


: openfile ( a n -- flag )
	2dup outfilename place " .norm" outfilename +place
	slurp over inptr ! inbuf 2!
	ioerr @ 0if
		outfilename count creat ioerr @ 0if
			outfilename count type cr
			outh !
			inbuf 2@ nip 2* dup allocate swap 
			over outptr ! outbuf 2!
			true
		;then
	then
	false
	;

: clean-up inptr free outptr free outh @ close ;

: >unicode 
	>uni
	inbuf dup cell+	| **in *inlef
	outbuf dup cell+	| **out *outleft
	swap @ swap
	iconv
	;
: unicode> ;
: normalize  ;
: savefile ;

: main 
	argc 1 >if 
		argc 1 do
			i argv openfile if
				>unicode 
				| normalize unicode>
				| savefile clean-up
			then
		loop
	then ;
