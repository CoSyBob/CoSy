| vim: ft=reva
|
| process.f
|
| This program demonstrates usage of the os/process library.
| Ensure that reva\bin is in your library search path!

needs os/process
needs os/fs
with~ ~process

create rp 1024 allot
  appdir " reva.exe" add-path rp lplace

: reva-path appname zcount ;


create mystr 100 allot
quote %
  ." hello from the started process!" cr
  bye
% mystr lplace
: the-string mystr lcount ;


: start-it ( -- process )
." starting process " reva-path type cr
  reva-path create-process0
  dup RSS_PROCESS_ALL start-process drop

." the stdin  fd of the child process: " dup get-to-fd   . cr
." the stdout fd of the child process: " dup get-from-fd . cr
;


: check-alive ( process -- process )
  dup is-alive
  ." status of the process: " . cr
;


: send-it ( process -- process )
 dup the-string send-to-process ." bytes sent: " . cr
 dup close-to drop
;


create mytmp 1024 allot
: read-it ( process -- process )
  dup mytmp 1024 receive-from-process
  ." bytes read: " dup . cr
  dup 0if drop else
    mytmp swap type cr
    read-it
  ;then
;


: stop-it ( process -- )
  RSS_PROCESS_WAIT release-process drop
;

: go
  start-it
  send-it
  read-it
  stop-it
;


