| Simple version of Unix "find" utility

needs os/dir
needs string/regex

| these are fed from the command-line
create startpath 256 allot
variable findrx

| This converts a "filespec" into a regular expression
: pathregex ( a n -- a' n' )
	pad off
	bounds do
		i c@ 
		case
			'* of '. pad c+place '* pad c+place endof
			'. of '\ pad c+place '. pad c+place endof
			'? of '. pad c+place endof
			pad c+place
		endcase
	loop
	pad count
	;

: getargs
	argc 3 =if
		1 argv startpath place
		2 argv pathregex regex_compile findrx !
	else
		." syntax: " 0 argv type_ ." startpath filespec" cr bye
	then
	;

: action 2dup findrx @ regex_find if 2swap fullname type cr then 2drop ;
::
	getargs
	['] action dup startpath count rdir
	; is ~sys.appstart

1 argv '. split drop  makeexename (save)
