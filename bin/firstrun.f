| This gets run the first time Reva runs:


| try to set console:

defer bred
defer blk
defer clear

: console " needs os/console" ['] eval catch dup 0if 
	" make bred red bold fg ; make blk white fg ; make clear cls ;" eval
	then not ;

: sqlite? " needs db/sqlite push~ ~db ~sqlite sqlite  pop~" eval ;

: dosetup | main setup stuff
	bred ." Welcome to the Reva first-run setup!" cr
	blk
	;

: failsetup | can't proceed, things are too wrong
	cr cr
	quote X
It seems that you have not unpacked the Reva distribution correctly, since
I cannot initialize the console libraries.
	X type cr
	os if
		| linux
		quote X
Make sure you have "libncurses.so" installed, and that you have permission to
use it.
		X
	else
		| windows
		quote X
The file "pdcurses.dll" is usually in the "bin" subdirectory of the Reva tree.
It may be that you unpacked correctly, but haven't got the PATH set in Windows.
		X
	then 
	type cr bye
	;

: main
	| Can we even continue?
	console if dosetup else failsetup then 
	;
