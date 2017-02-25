| demonstrate use of 'onstartup' and 'onexit' words

: start1 ." Start 1" cr ;
: start2 ." Start 2" cr ;
: start3 ." Start 3" cr ;
: exit1 ." Exit 1" cr ;
: exit2 ." Exit 2" cr ;
: exit3 ." Exit 3" cr ;

with~ ~sys
' start1 onstartup
' start2 onstartup
' start3 onstartup
' exit1 onexit
' exit2 onexit
' exit3 onexit

' bye is appstart
." Creating 'onstart' application.  Run it to see what order startup/exit code is run" cr 
" onstart" makeexename (save) 
