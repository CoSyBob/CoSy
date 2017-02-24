| poor-mans' grep

needs string/regex

| syntax: grep regex filename

: main
	2 argv slurp 1 argv regex_find!
	dup 0if ." Not found" cr ;then
	0do
		i regex_getmatch type cr	
	loop
	;

' main is ~sys.appstart
save grep
