| Generate "MD5" checksum for a list of files
| vim: ft=reva :


needs crypt/md5

: do1file ( n -- )
	argv 2dup slurp over >r
	md5 type space type cr
	r> free 
	;
: dofiles argc 1 do i do1file loop ;

with~ ~sys
' dofiles is appstart
without~

." Generating MD5 executable... "
" md5" makeexename (save) ." done!" bye

