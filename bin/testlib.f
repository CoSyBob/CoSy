| vim: ft=reva :
| Test whether libraries can be loaded without incident:

| Default ordering
: catching ." The exception: " . ." was thrown" cr ;
	' catching is caught

needs util/contexts
reva
snap~ snappy

100 stack: needs$ 
: allocplace ( a n -- a' )
	dup 1+ 1+ allocate
	dup >r place r> ;
' ~  constant ROOT
: needs | make sure contexts are still ok after load!
	reset~
	parsews allocplace dup needs$ push
	." Loading: " count type cr

	needs$ peek count in~ ~priv (needs)
	in~ ~priv contexts peek ROOT <>
	in~ ~priv contexts stack-size 1 <> or if
		." BAD: "  needs$ peek count type cr 
		-1 throw
	then
	needs$ pop free
	snappy
	;


| the loader code:
: try quote "
needs alg/structs
needs alg/bubblesort
needs alg/enum
needs alg/hsort
needs alg/insertsort
needs alg/quicksort
needs alg/sort-common
needs alg/array
needs alg/stack
needs alg/list
needs ansi
needs asm
needs callbacks
needs choices
needs crypt/md5
needs crypt/rc4
needs date/calendar
needs date/church
needs date/hebrew
needs date/holidays
needs date/islam
needs date/iso
needs date/julian
needs date/sedra
needs db/sqlite
needs helper
needs math/doubles
needs math/floats
needs math/mod
needs net/sockets
needs net/cgi
| needs os/console
needs os/dir
needs os/shell
needs random/gm
needs random/simple
needs string/iconv
needs string/justify
needs string/misc
needs string/regex
needs string/soundex
needs string/trim
needs util/auxstack
needs util/classes
needs util/contexts
needs util/eachline
needs util/locals
needs util/misc
needs util/scase
needs util/tasks
needs util/zlib
needs ui/gl
needs ui/glu
needs ui/glut
needs os/exception
needs debugger
needs util/portio
" ;

os [IF]
: tryos
quote "
needs ui/gtk
needs ui/gtk2
" ;
[ELSE]
| only Windows
: tryos
quote "
needs os/rapi
needs os/registry
needs ui/cd
needs ui/gui
needs ui/gui-db
needs ui/gui-iup-img
needs ui/iup
| needs os/com
" ;
[THEN]


: trylibs
	try eval
	tryos eval
	;
: report
	cr
	." Search order: " .~ cr  cr
	." All contexts: " .contexts cr  cr
	." Libraries: " .needs cr cr
;

: main
	['] trylibs catch dup
	if
		." Caught exception: " . cr
	then
	report
	bye
	;

main
