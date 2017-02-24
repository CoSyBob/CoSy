: dumpkeys
	ekey dup .x
	3 =if cr bye then
	dumpkeys
	;

." Press any key to see its keycode in hex.  Press Ctrl+C to quit:" cr
dumpkeys 
