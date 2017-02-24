| Brownian motion generator
| brownian.rf
| 17-apr-2006 mcarter created
| 17-apr-2006 danny tail call optimization - quick'n'dirty support of multple particles
| 17-apr-2006 danny tried to make the stuff more "Forth'ish"
| 17-apr-2006 mcarter: 78 cols. 1 in 10 particles leaves residue
| 18-apr-2006 danny: added a border, some more factoring
| released into public domain


needs os/console
needs random/simple

40 value nof-particles
variable positions
here positions !
nof-particles 2 * cells allot

: draw-border
  79 1 do i 1 gotoxy '# emit i 25 gotoxy '# emit loop
  25 1 do 1 i gotoxy '# emit 78 i gotoxy '# emit loop
;

: within ( n min-val max-val -- n ) -rot max min ; | constrain n in [min-val..max-val]
: x+- ( n -- n ) 3 choose 1- + 2 77 within ;
: y+- ( n -- n ) 3 choose 1- + 2 24 within ;
: x+-! ( a -- ) dup @ x+- swap ! ;
: y+-! ( a -- ) dup @ y+- swap ! ;

: get-address ( n -- a ) 2 * cells positions @ + ;
: get-xy ( n -- x y ) get-address dup @ swap cell+ @ ;

: init-particle get-address dup 40 swap ! cell+ 20 swap ! ;
: init nof-particles 0 do i init-particle loop ;

: draw ( n c -- ) swap get-xy gotoxy emit ;
: trail ( n--) dup 10 mod if 32 else 46 then draw ;
: perturb ( n--) get-address dup x+-! cell+ y+-! ;
: show ( n--) dup 26 mod 'A + draw ;

: jiggle 10 ms nof-particles 0 do i trail i perturb i show loop ; 
 
| loop over jiggle until a key press
: _go key? not if jiggle _go ;then ;
: go init cls draw-border _go key drop ; | call this for fun

go
