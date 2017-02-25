alias: \ |
alias: I i
alias: lshift <<
alias: rshift >>
: erase 0 fill ;
: 2constant create , , does> dup cell+ @ swap @ ;
: .ms 1000 /mod (.) type '. emit 3 '0 (p.r) type space ;
\ The Computer Language Shootout
\ http://shootout.alioth.debian.org/
\ Contributed by Ian Osgood
\ modified by Anton Ertl
\ Joshua Grams removed most of the double cell manipulation
\  and added island detection.

: d2/ inline{ D1 F8 D1 3E } ;
: d2* inline{ D1 26 D1 D0 } ;
: enum ( n -- )  0 do I constant loop ;
: table create does> ( i -- t[i] )  swap cells + @ ;

7 enum         E   SE   SW    W   NW   NE   STOP
table offset   1 ,  7 ,  6 , -1 , -7 , -6 ,    0 ,
table rotate  SE , SW ,  W , NW , NE ,  E , STOP ,
table reflect  E , NE , NW ,  W , SW , SE , STOP ,

\ paths are more easily transformable than bit masks

create path    5 cells allot
create offsets 6 cells allot

1024 allot \ padding for Pentium 4 and bigforth shortcomings

: init-path ( 4*dirs -- )
   E path 5 0 do tuck ! cell+ loop drop ;
: rotate-path
   path 5 0 do dup @ rotate  over ! cell+ loop drop ;
: reflect-path
   path 5 0 do dup @ reflect over ! cell+ loop drop ;

: path-offsets
   0 offsets !
   path offsets
   5 0 do
      over @ offset
      over @ +
      over cell+ !
      swap cell+ swap cell+
   loop 2drop ;
: minimum-offset ( -- n )
   offsets @
   6 1 do offsets I cells + @ min loop ;
: normalize-offsets
   minimum-offset negate
   6 0 do dup offsets I cells + +! loop drop ;
: offsets-mask ( -- mask )
   0
   6 0 do
      offsets I cells + @
      1 swap lshift or
   loop ;

\ make and store the twelve transformations of the path

: path-mask ( -- mask )  path-offsets normalize-offsets offsets-mask ;
: path-masks ( 4*dirs -- )
                          false , \ used flag
            init-path path-mask ,
   5 0 do rotate-path path-mask , loop
         reflect-path path-mask ,
   5 0 do rotate-path path-mask , loop ;

13 cells constant /piece

\  all paths start with an implicit E

create pieces
 STOP SE  E  E path-masks
 STOP NE  E SE path-masks
 STOP SW SE  E path-masks
 STOP SE SW  E path-masks
   SW  W  E SE path-masks \ one backtrack, since this shape branches
 STOP SE NE SE path-masks
 STOP NE SE SE path-masks
 STOP  E SW SE path-masks
 STOP  E SE  E path-masks
 STOP NE SE  E path-masks

variable #solutions
create smallest 64 allot
create largest  64 allot

variable board    \ high word of board; low word on stack

1024 allot \ padding for Pentium 4 and bigforth shortcomings

: put-piece ( piece shift -- )
   over pieces - /piece / '0 + >r ( R: piece-char )
   here + swap @ ( buf mask )
  | begin
   repeat
      dup 1 and if over r@ swap c! then
      swap 1+ swap 2/
   | dup 0= until 
   dup while
   2drop r> drop ;

\ extract solution from stack and store at HERE
\ (ignore piece0, it was put in solve0)
\ (non-destructive because we need the data for backtracking).
: store-solution ( piece0 start-shift piece1 shift1 ... pieceN board )
   depth 2 - pick ( absolute-shift )
   depth 3 - 2 swap do
      i pick over put-piece
      i 1- pick +
  | -2 +loop 
	-2 skip loop
   drop ;

: check-solution
   here 64 smallest 64 cmp 0 <if here smallest 64 move then
   largest 64  here 64 cmp 0 <if here  largest 64 move then
   1 #solutions +! ;  \ throw if #solutions == NUM

: (reverse) 
	2dup < not if ;then
	dup c@ >r  over c@ over c!  over r> swap c!
|	1 /string
	swap 1+ swap 1-
	(reverse)
	;

: reverse ( buf size -- ) 1- over + (reverse) 2drop ;

: .line ( line -- line+6 )
   5 0 do dup c@ emit space 1+ loop cr 1+ ;
: .solution ( buffer -- )
   5 0 do .line 1+  space .line loop drop cr ;

: record ( [st] -- [st] )
   store-solution  check-solution
   here 64 reverse   check-solution here 64 reverse ;

\ initial board, with edges filled in
%0000011000001000001100000100000110000010000011000001000001100000L
	2constant init-board

\ board mask for a hexagon with an empty center
%110000101000011 constant empty-hex

$80000000 constant hi-bit

\ is it a single-cell island?
   \ the center (empty) cell is 7 bits in.
: island? ( board bit -- flag )  empty-hex * 7 rshift tuck and = ;

\ fun with bit manipulation :)
: fill-leading ( u -- u' )  dup 1- or ;
: first-empty ( u -- bit )  dup dup 1+ or xor ;

\ return a bit-mask for the second empty cell on the board.
: second ( board -- bit )  fill-leading first-empty ;

\ check two spots for single-cell islands
: prune? ( board -- flag )
   dup 1 island? if drop true else dup second island? then ;


\ remove filled cells at the beginning of the board
: (shift-board)
	over 1 and not if ;then
	d2/ hi-bit or  rot 1+ -rot
	(shift-board)
	;
: shift-board ( board -- shift board' )
	0 swap board @ 
	(shift-board)
	board ! ;
	;

\ restore filled cells at the beginning of the board
: unshift-board ( shift board -- board' )
   board @ rot 0 ?do 
   d2* swap 1+ swap loop board ! ;


variable #solves
: solve ( board -- board )
	#solves ++
   dup prune? if ;then
   pieces  10 0 do
      dup @ if
         /piece +
      else
         true over ! cell+        \ mark used
         12 0 do
            2dup @ and 0if
               tuck @ xor       \ add piece
               dup invert if
                  shift-board solve unshift-board
               else record then
               over @ xor swap  \ remove piece
            then
         cell+ loop
         false over /piece - !    \ mark unused
      then
   loop drop ;

\ Optimization: fill it one piece on all possible locations on the first
\  half of the board, then recurse normally.
\  When solutions are found, record both the solution and 180-rotation.
\  Empirically, piece 4 caused the most cutoffs

: dlshift ( d n -- d' )  0 ?do d2* loop ;
: dand ( d d -- d )  rot and >r and r> ;
: dxor ( d d -- d )  rot xor >r xor r> ;

: solve-row ( piece offset -- piece )
   dup 5 + swap 
   do
      dup @ 0 i dlshift init-board dand or 0if   \ fits?
         dup i put-piece
         dup @ 0 i dlshift init-board dxor board !
         shift-board solve 2drop
      then
   loop ;
: solve0
   pieces 4 /piece * +   \ use piece 4
   true over ! cell+   \ mark it used
   12 0 do
      0  solve-row
      7  solve-row
      13 solve-row
      \ ignore rotations of longest piece orientations
      i 4 <> i 7 <> and if 20 solve-row then
   cell+ loop drop ;
: main
	ms@ >r
   0 #solutions !
   smallest 64 '9 fill
   largest  64 '0 fill
   here 64 erase
   solve0
   #solutions @ . ." solutions found" cr cr
   #solves @ . ." #solves" cr 
   smallest .solution
   largest  .solution 
   ms@ r> - ;

reset 
main 
." Ran in " .ms ." ms" cr bye

0 [IF]
 build & benchmark results

RUNNING SCRIPT: meteor.bigforth

Mon Jan 29 23:05:17 PST 2007


=================================================================
COMMAND LINE (%A is single numeric argument):

 /opt/bigforth/bigforth $BIGFORTH_FLAGS ../meteor.bigforth %A


PROGRAM OUTPUT
==============
2098 solutions found

0 0 0 0 1 
 2 2 2 0 1 
2 6 6 1 1 
 2 6 1 5 5 
8 6 5 5 5 
 8 6 3 3 3 
4 8 8 9 3 
 4 4 8 9 3 
4 7 4 7 9 
 7 7 7 9 9 

9 9 9 9 8 
 9 6 6 8 5 
6 6 8 8 5 
 6 8 2 5 5 
7 7 7 2 5 
 7 4 7 2 0 
1 4 2 2 0 
 1 4 4 0 3 
1 4 0 0 3 
 1 1 3 3 3 

[THEN]
