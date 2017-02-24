| Traditional 'file dump'.
0 value myfile
0 value print?
create hexbuf 16 allot	| 16 byte read buffer
create dump$  17 allot

: openfile ( n -- ) argv print? if 2dup type cr then open/r to myfile ;
: printname? ( n -- n ) dup 2 > to print?  ;

0 value dumpoffs
: dumpasc
    dump$ count dup 0if 2drop else
        16 over - 3 * spaces type
    then cr dump$ off ;
: isprint? 32 127 between ;
: >printable dup isprint? not if drop '. then ;
: dump 0; dump$ off 
    dumpoffs .x 0do | iterate for each line:
        dup c@ dup >printable dump$ c+place .2x space 1+
		1 +to dumpoffs
    loop drop dumpasc ;

: dodump
	hexbuf 16 myfile read 0;
	hexbuf swap dump dodump ;

: main 
	argc printname? 1 ?do 
		0 to dumpoffs 
		i openfile 
		dodump 
		myfile close 
	loop bye ;

' main is ~sys.appstart
" dump" makeexename (save) bye
