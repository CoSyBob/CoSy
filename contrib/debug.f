: debug	cr .s cr src @ >r 0 src ! ." dbg> " interp r> src ! ;
: go rdrop ;


: test ." before debug..." cr debug ." after debug! " cr ;

test ." done" cr
