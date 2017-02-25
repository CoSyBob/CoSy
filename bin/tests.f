#! reva

needs os/dir
needs testing

: do-one-lib ( a n -- )
	." Processing: " 2dup type cr

	~priv.(needs)		| include this library
	" test" eval
	;

: exclude ( a n b m -- | a n ) 
	2over 2swap search 0; 3drop 2drop rdrop ;
: (dolibs) ( a n -- )
	in~ ~os fullname 
	" CVS/" exclude
	" .svn/" exclude
	" .exe" exclude
	" /arm/"  exclude
	" debugger" exclude
	" disasm" exclude
	" helper" exclude
	" testing" exclude
	" ansi" exclude
	| a n
	libdir nip /string	| remove the path including 'lib'
	do-one-lib
	;
: dolibs
	| iterate over libraries and process each one ...
	['] (dolibs) ['] 2drop libdir in~ ~os rdir
	;

dolibs bye
