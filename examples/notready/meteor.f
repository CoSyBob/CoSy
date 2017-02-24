| The Computer Language Shootout
| http://shootout.alioth.debian.org/
| Contributed by Ian Osgood
| modified by Anton Ertl
| Joshua Grams removed most of the double cell manipulation
|  and added island detection.
| Modified for Reva 6.1.5 (http://ronware.org/reva/wiki/6.1.5) 
|  by Ron Aaron

: d2/ inline{ D1 F8 D1 3E } ;
: d2* inline{ D1 26 D1 D0 } ;

: enum ( n -- )  0 do i constant loop ;
: table create does> ( i -- t[i] )  swap cells + @ ;

7 enum         E   SE   SW    W   NW   NE   STOP
table offset   1 ,  7 ,  6 , -1 , -7 , -6 ,    0 ,
table rotate  SE , SW ,  W , NW , NE ,  E , STOP ,
table reflect  E , NE , NW ,  W , SW , SE , STOP ,

| paths are more easily transformable than bit masks

create path    5 cells allot
create offsets 6 cells allot

1024 allot | padding for Pentium 4 and bigforth shortcomings

: init-path ( 4*dirs -- )
	E path 5 0do tuck ! cell+ loop drop ;
: rotate-path
	path 5 0do dup @ rotate  over ! cell+ loop drop ;
: reflect-path
	path 5 0do dup @ reflect over ! cell+ loop drop ;

: path-offsets
	0 offsets !
	path offsets
	5 0do
		over @ offset
		over @ +
		over cell+ !
		swap cell+ swap cell+
	loop 2drop ;
: minimum-offset ( -- n )
	offsets @
	6 1 do offsets i cells + @ min loop ;
: normalize-offsets
	minimum-offset negate
	6 0do dup offsets i cells + +! loop drop ;
: offsets-mask ( -- mask )
	0
	6 0do
		offsets i cells + @
		1 swap << or
	loop ;

| make and store the twelve transformations of the path

: path-mask ( -- mask )  path-offsets normalize-offsets offsets-mask ;
: path-masks ( 4*dirs -- )
	                       false , | used flag
	         init-path path-mask ,
	5 0 do rotate-path path-mask , loop
	      reflect-path path-mask ,
	5 0 do rotate-path path-mask , loop ;

13 cells constant /piece

|  all paths start with an implicit E

create pieces
 STOP SE  E  E path-masks
 STOP NE  E SE path-masks
 STOP SW SE  E path-masks
 STOP SE SW  E path-masks
   SW  W  E SE path-masks | one backtrack, since this shape branches
 STOP SE NE SE path-masks
 STOP NE SE SE path-masks
 STOP  E SW SE path-masks
 STOP  E SE  E path-masks
 STOP NE SE  E path-masks

variable #solutions
create smallest 64 allot
create largest  64 allot

variable board    | high word of board; low word on stack

1024 allot | padding for Pentium 4 and bigforth shortcomings

: put-piece ( piece shift -- )
	over pieces - /piece / '0 + >r ( R: piece-char )
	here + swap @ ( buf mask )
	repeat
		dup 1 and if over r@ swap c! then
		swap 1+ swap 2/
	dup 
	| 0= until
	while
	2drop r> drop ;

| extract solution from stack and store at HERE
| (non-destructive because we need the data for backtracking).
: store-solution ( pieceN shiftN ... piece0 board )
	| here 64 [char] * fill
	0 ( absolute-shift )
	depth 1- 2 swap do
		i pick over put-piece
		i 1- pick +
	-3 skip | -2 +loop 
	loop
	drop ;

: .line ( line -- line+6 )
	5 0do dup c@ emit space 1+ loop cr 1+ ;
: .solution ( buffer -- )
	5 0do .line 1+  space .line loop drop cr ;

: record ( [st] -- [st] )
	store-solution  | here .solution
	here 64 smallest 64 cmp 0 <if here smallest 64 move then
	largest 64  here 64 cmp 0 <if here  largest 64 move then
	1 #solutions +! ;  | throw if #solutions == NUM

| initial board, with edges filled in
| 2 base !
| 0000011.000001.0000011.000001.0000011.000001.0000011.000001.0000011.00000
| %00000110000010000011000001000001 %10000010000011000001000001100000

| board mask for a hexagon with an empty center
%110000101000011 constant empty-hex

$80000000 constant hi-bit


| is it a single-cell island?
	| the center (empty) cell is 7 bits in.
: island? ( board bit -- flag )  empty-hex * 7 >> tuck and = ;

| fun with bit manipulation :)
: fill-leading ( u -- u' )  dup 1- or ;
: first-empty ( u -- bit )  dup dup 1+ or xor ;

| return a bit-mask for the second empty cell on the board.
: second ( board -- bit )  fill-leading first-empty ;

| check two spots for single-cell islands
: prune? ( board -- flag )
	dup 1 island? if drop true else dup second island? then ;

| remove filled cells at the beginning of the board
: (shift-board)
	0 swap board @ 
: (shift-again)
	over 1 and 0if ;; then
	| while true:
	d2/ hi-bit or  rot 1+ -rot
	(shift-again)
	;

: shift-board ( board -- shift board' ) (shift-board) board ! ;

| restore filled cells at the beginning of the board
: unshift-board ( shift board -- board' )
	board @ rot 0 ?do d2* swap 1+ swap loop board ! ;

: invert -1 xor ;
: solve ( board -- board )
	dup prune? if ;; then
	pieces  10 0do
		dup @ if
			/piece +
		else
			true over ! cell+        | mark used
			12 0do
				2dup @ and 0if
					tuck @ xor       | add piece
					dup invert if
						shift-board solve unshift-board
					else record then
					over @ xor swap  | remove piece
				then
			cell+ loop
			false over /piece - !    | mark unused
		then
	loop drop ;

: main
	.s cr
	#solutions off
	smallest 64 '9 fill
	largest  64 '0 fill
	.s cr
		%10000010000011000001000001100000
		%00000110000010000011000001000001 
		board ! solve drop
	#solutions ? ." solutions found" cr cr
	smallest .solution
	largest  .solution ;

main bye

|||

 build & benchmark results

RUNNING SCRIPT: meteor.bigforth-4.bigforth

Wed Jan 24 20:54:26 PST 2007


=================================================================
COMMAND LINE (%A is single numeric argument):

 /opt/bigforth/bigforth $BIGFORTH_FLAGS ../meteor.bigforth-4.bigforth %A


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

