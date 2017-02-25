: testkeys
	repeat
		key? dup .
		if ekey 27 - 0; drop then
		100 ms
	again ;

." This example will print a '0' if no key is pending; otherwise it will" cr
." print a '-1'.  Press ESC to quit" cr

testkeys cr bye
