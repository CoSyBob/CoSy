variable sock

| Buffers for our strings
create myname 21 allot
create mytext 81 allot
create myserver 81 allot
create myto 21 allot

| This is needed because the socket library defines 'accept', and we do NOT want
| to use  the new one here!
: myaccept accept ;

| Definitely need socket support!
needs net/sockets
needs date/calendar  | for (today)
with~ ~date

| Generic prompted-input
| args are:  buffer buffer-len prompt prompt-len
| Quits the program on failure:
: prompt ( a n a n -- )
	type 
	dup ." (<" . ." chars): "
	swap >r				| r: dest buffer
	scratch swap myaccept	| n
	dup 0if ." You must answer my questions!" cr bye then
	scratch swap r> place
	cr
	;

: init
	myname 20   " What is your name?" prompt
	myserver 80 " Server to use?" prompt
	myto 20   " Who to send it to?" prompt
	mytext 80   " What do you want to say?" prompt

	myserver count 25 
	connectsocket dup -1 =if 
		." could not open a socket, sorry" cr bye 
	then sock ! ;

: >sock sock @ -rot  0 send -1 =if ." error sending" then  ;
: >sockln >sock crlf >sock ;
: sock> sock @ -rot 0 recv ;
: getresponse scratch  4096 sock> scratch swap type ;
: resp scratch 3 cmp not ;
: resp220 " 220" resp ;
: resp250 " 250" resp ;
: resp354 " 354" resp ;

: ok resp220 resp250 resp354 or or not if ." Error: " scratch 3 type cr bye then ;

: smtpln >sockln getresponse ok ;
: smtp-common >sock smtpln ;
: EHLO " EHLO " smtp-common ;
: MAIL-FROM " MAIL FROM: " smtp-common ;
: RCPT-TO " RCPT TO: " smtp-common ;
: DATA " DATA" smtpln ;
: QUIT " QUIT" smtpln ;
: END " ." >sockln ;
: msg-header >sock >sockln ;

: sendmail
	" reva" EHLO 
	" <reva@ronware.org>" MAIL-FROM
	myto count RCPT-TO
	DATA
	myname count " From: " msg-header
	" Testing Reva SMTP " " Subject: " msg-header
	myto count " To: " msg-header
	(today) " Date:" msg-header

	crlf >sockln
	mytext count >sockln 

	END
	QUIT 
	." done..." cr
	;


init sendmail sock @ closesocket bye
