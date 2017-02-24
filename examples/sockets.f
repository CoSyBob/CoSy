needs net/sockets

variable sock

: init
	" api.hostip.info" 80 connectsocket	|  -1 on failure, else a valid socket we can talk to
	sock ! ;

: ok
	sock @ 1+ 0if ." Couldn't open a socket." cr bye then
	." Got a valid socket: " sock @ . cr
	;


: getpage 
	" POST get_html.php?ip=12.215.42.19" pad place
	crlf pad +place
	sock @  pad count 0 send ." send: " . cr
	sock @ scratch 4096 0 recv ." recv: " dup . cr 
	scratch swap type cr
	;
	

init ok getpage sock @ closesocket bye
