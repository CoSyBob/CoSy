| vim:  ft=reva
|
| dhttpd
|
| Danny's web server ;)
|
| A small and simple web server example for Reva FORTH.
|
| Author: Danny Reinhold / Reinhold Software Services
| Reva's license terms also apply to this file!

needs net/sockets
needs net/mime
needs alg/structs
needs string/misc
needs os/fs
needs os/shell
needs os/process

~
with~ ~process

: .version ." Danny's web server 0.01" cr ;
: instdir appdir rem-separator split-path 2drop ;
| overwrite these words if necessary...
8585 value port | 8080 doesn't require root privileges on Linux
create (docroot) 256 allot  | default is "test" off the Reva directory
  instdir " test" add-path (docroot) lplace

: document-root (docroot) lcount ;

1024 constant mem-size

create tmp-mem 100 allot
: read-it ( process a1 -- process a1 )
  over tmp-mem 100 receive-from-process 0;
  ." bytes read from cgi: " dup . cr

  | process a1 n
  over swap    | process a1 a1 n
  tmp-mem swap | process a1 a1 a2 n
  rot          | process a1 a2 n a1
  +lplace      | process a1

." read so far: " dup lcount type cr

  read-it
;

| calls the cgi script (a1, n1) with the
| paremeter string (a2, n2) and returns
| the cgi's output as a long counted string in a.
| the parameter string is passed to the
| cgi script via the QUERY_STRING
| environment variable...
| ATTENTION: you have to free the returned memory area!
: call-get-cgi ( a1 n1 a2 n2 -- a )
|  " QUERY_STRING" setenv
  ." ignoring cgi attributes: <" type ." >" cr

  create-process0
  dup RSS_PROCESS_FROM start-process
  0if
    drop
    " <body><h1>CGI error!</h1>cannot call the desired CGI script!</body>"
    dup cell+ allocate dup >r lplace r>
  ;then

  | allocate some memory
  mem-size allocate
  0 over !

  | read the CGI's output
  read-it

  swap
  RSS_PROCESS_WAIT release-process
  drop
;



struct: mysockaddr
  short: sin_family
  short: sin_port
  2 longs[]: sin_addr
  8 bytes[]: sin_zero
struct;


: bind-port ( -- )
  tcpsock sockbad? if drop  -1 ;; then

  " mysockaddr" (sallot) | socket sockaddr
	port htonl PF_INET or over sin_family !
  0    over sin_addr !    | INADDR_ANY

  over swap sizeof mysockaddr
  bind dup 0 <if 2drop 0 ;then
  ." successfully bound to the port" cr
;


: release-port ( socket -- )
  closesocket drop
;


create mytmp 1024 allot
: read-request ( accept-socket -- accept-socket a n )
  dup mytmp 1024 0 recv mytmp swap 
;

: nl 10 pad c+lplace ;

: write-text ( socket a n -- socket )
|  2dup ." sending message:" cr ." ---" cr type cr ." ---" cr
  >r >r dup r> r>
  dup >r zt r> 0 send drop
;

: write-header ( socket mime-type-a mime-type-n -- socket )
  " HTTP/1.1 200 OK" pad lplace nl
  " Server: dannyserver/0.01" pad +lplace nl
  " Connection: close" pad +lplace nl
  " Content-type: " pad +lplace
  pad +lplace nl nl
  pad lcount write-text
;

: check-path ( a n -- a' n' )
  2dup '/ /char drop dup 0if drop else '\ swap c! check-path ;then
;

: give-file ( socket a n -- socket )
  ." searching for document " 2dup type cr
  check-path
  2dup get-mime 2swap
  slurp

  >r >r write-header r> r> write-text
;


: check-and-process-cgi ( socket a n -- socket a n is-cgi-flag )
  2dup '? split 0if 2drop 0 ;then

  2dup get-suffix " .f" cmp if 0 ;then

    ." Executing script: " 2dup type cr
    ." Starting via command: "
    scratch lplace
    appdir " reva.exe" add-path  pad lplace
    "  " pad +lplace
    scratch lcount
    2dup pad +lplace
    pad lcount
    2dup type cr
    " noattrs"
    call-get-cgi
    -rot 2drop lcount
    >r >r 2drop 2drop r> r>
| FIXME: free the memory
    -1
;

: serve-file ( socket a n -- socket )
  2dup " /" cmp 0if 2drop " index.html" then
  document-root 2swap add-path

  check-and-process-cgi
  if
    write-text
  else
    2dup stat 0
    <if
      | skip unexisting file for now...
      ." ---" cr
      ." the requested file does not exist: " type cr
      ." ---" cr
    else
      2dup ." Serving file: " type cr
      give-file
    then
  then
;


| (a,n) is a string starting with " GET "...
: process-get-request ( socket a n -- socket )
  4 /string | skip " GET "
  32 split if
    2swap 2drop
    2dup ." GET REQUEST - REQUESTED PATH: " type cr
    serve-file
  then
;


: check-and-process-get-request ( socket a n -- socket a' n' is-get-request-flag )
  " GET" | socket a n a2 n2
  search2
  if
    2dup >r >r process-get-request r> r>
    -1
  else
    2drop 0
  then
;


: check-and-process-post-request ( socket a n -- socket a' n' is-post-request-flag )
  " POST" | socket a n a2 n2
  search2
  if
    ." ##########" cr
    ." POST REQUEST!!!!" cr
    type cr
    ." ##########" cr
    .s cr
    -1
  else
    2drop 0
  then
;


: process-request ( socket a n -- socket )
  | is it a GET request?
  check-and-process-get-request
  if
    2drop ;;
  then

  | is it a POST request?
  check-and-process-post-request
  if
    2drop ;;
  then

  2drop
;


: wait-for-requests ( socket -- socket )
  dup 1 listen 0 <if
    ." error while listening on socket " . cr ." terminating" cr bye
  then

  dup 0 0 accept dup -1 >if
    ." wow - a connection !!!" cr
    read-request
    process-request

   dup 2 shutdown drop

   closesocket drop
  else
    2drop
  then

  wait-for-requests  | endless loop...
;


| start the server
: serve
  bind-port -1 >if
    wait-for-requests
    release-port
  then
;


.version
." Document root is: " document-root type cr
." Using port: " port . cr
serve

