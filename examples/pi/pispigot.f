| computer language shootout
| http://shootout.alioth.debian.org/
| contributed by albert van der horst, ian osgood
| modified for Reva http://ronware.org/reva/ 
| by Ron Aaron

: .ms 1000 /mod (.) type '. emit 3 '0 (p.r) type space ;
needs math/doubles
~doubles
| read num from last command line argument:
: getnum argc argv >single 0if 2drop 10 then ;
getnum constant num

| arbitrary precision arithmetic
| a p-number consists of a count plus count cells, 2-complement small-endian

| same as "dup @ cells +"
: p[] [ $048d188b , $98 1, ;inline
| same as "i cells +"
: i+  [ $04245c8b , $8d241c2b , $9804 2, ;inline

forth
| give sign of p
: p0< ( p -- flag ) p[] @ 0 < ;

| copy a p-number to another buffer
: pcopy ( src dst -- ) over @  1+ cells move ;

| check for overflow, extend the p-number if needed
: ?carry ( carry p -- ) 2dup p0< <>if 1 over +! p[] ! else 2drop then ;
| in-place multiply by an unsigned integer
variable n1
variable p1
: p* p1 ! n1 ! |  {  n p --  }
  p1 @ dup >r p0< 0L ( sign dcarry )
  r> @ 1+ 1 do
    p1 @
	i+ @       ( digit )
    n1 @ um* d+ swap ( carry digit )
    p1 @ i+ ! 0
  loop
  rot n1 @ um* d+ drop  p1 @ ?carry ;
| ensure two p-numbers are the same size before adding
| 0 constant sign
variable sign
variable n2
variable p2
: extend n2 ! p2 ! | { p n -- }
  p2 @ p0< sign !  | to sign 
  p2 @ @ 1+  n2 @ p2 @ +!
  p2 @ @ 1+ swap
  do sign @ p2 @ i+ ! loop ;

: ?extend ( p1 p2 -- p1 p2 )
	over @ over @ - ?dup if
		dup 0 < if
			>r over r> negate
		else
			over swap
		then 
		extend
  then ;

| in-place addition of another p-number
variable s3
variable p3
: p+  ?extend p3 ! s3 ! | { src p -- }
  s3 @ p0< p3 @ dup >r p0<  0L ( sign sign dcarry )
  r> @ 1+ 1 do
    p3 @   i+ @ 0 d+
    s3 @ i+ @ 0 d+ swap
    p3 @   i+ ! 0
  loop
  drop + + p3 @ ?carry ; | add signs, check for overflow

| in-place subtraction of another p-number
: p-  ?extend p3 ! s3 ! | { src p -- }
  s3 @ p0< p3 @ dup >r p0<  0L ( sign sign dcarry )
  r> @ 1+ 1 do
    p3 @   i+ @ 0 d+
    s3 @ i+ @ 0 d- swap
    p3 @ i+ ! s>d
  loop
  drop + + p3 @ ?carry ; | add signs, check for overflow

|
| pi-spigot specific computation
|

| approximate upper limit on size required (1000 -> 1166)
num 2* cells constant size

| current z transformation
create aq 1 , 1 , size allot
create ar 1 , 0 , size allot
    | "as" identical zero and remains so
create at 1 , 1 , size allot

| generate non-zero parts of next matrix ( k 4k+2 2k+1 )
variable k
: generate ( -- q r t ) 1 k +!   k @  dup 2* 1+  dup 2* swap ;

| here is used as a temporary p-number

| multiply z from the left
: compose< ( bq br bt -- )
  dup at p*  ar p*  aq here pcopy  here p*  here ar p+  aq p* ;

| multiply z from the right
: compose> ( bt br bq -- )
  dup aq p*  ar p*  at here pcopy  here p*  here ar p-  at p* ;

| calculate z at point 3, leaving integer part and fractional part.
| division is by multiple subtraction until the fractional part is
| negative.
: z(3)  ( -- n pfract ) 
	here  aq 
	over pcopy  3 
	over p* ar 
	over p+ 0 
	repeat
		swap at over p- dup p0< if ;then
		swap 1+
	again ;

| calculate z at point 4, based on the result for point 3
| and decide whether the integer parts are the same.
: z(4)same? ( pfract -- flag ) aq over p+  p0< ;

: pidigit ( -- nextdigit)
	repeat
		z(3) z(4)same? dup 0if
			nip generate compose< 
		then
		not
	while
    1   over 10 *   10   compose> ;

: .digit ( -- ) pidigit '0 + emit ;

: .count ( n -- ) 9 emit ." :"  (.) type cr ;

| spigot n digits with formatting
: spigot ( digits -- ) 0
	repeat
		10 +  2dup > dup if
			>r
			10 0do .digit loop  dup .count
			r>
		then
	while
	2dup 10 - do .digit loop  over - spaces  .count ;
ms@
num spigot 
ms@ swap - .ms
bye
