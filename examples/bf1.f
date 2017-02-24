| vim: ft=reva
|
| A simple brainfuck interpreter for Reva FORTH.
| Author: Danny Reinhold
|         (modified slightly by Ron Aaron)
| Reva's license terms also apply to this file.
| See: http://en.wikipedia.org/wiki/Brainfuck

30000 constant memory-size
create memory memory-size allot 
variable memory-pointer
variable instruction-pointer
2variable the-code

| This is an array of function pointers which gets filled in later:
create commands 256 cells dup allot commands swap 0 fill

: next-command ( -- c )
  the-code 2@ + instruction-pointer @ <if 0 ;then
  instruction-pointer @ c@
  instruction-pointer ++
;

: prev-command ( -- c )
  instruction-pointer --
  instruction-pointer @ c@
;

: bf ( a n -- ) memory memory-size 0 fill memory memory-pointer !  
	2dup the-code 2!
	drop  instruction-pointer ! 
	| fall-through to the bf interpreter:
: brainfuck next-command 0; commands swap cells + @ ?dup if execute then brainfuck ;

: skip-block ( level -- )
  0;

  next-command
  dup
  '[ =if drop 1+ skip-block ;then
  '] =if      1- skip-block ;then
  skip-block
;

: find-block-start ( level -- )
  0;

  prev-command
  dup
  '] =if drop 1+ find-block-start ;then
  '[ =if      1- find-block-start ;then
  find-block-start
;

| These are the actions:
: b> memory-pointer ++ ;
: b< memory-pointer -- ;
: b+ memory-pointer @ dup c@ 1+ swap c! ;
: b- memory-pointer @ dup c@ 1- swap c! ;
: b. memory-pointer @ c@ emit ;
: b, ~sys.>in @ c@  memory-pointer @ c! ;
: b[ memory-pointer @ c@ 0if 1 skip-block then ;
: b] memory-pointer @ c@ if prev-command drop 1 find-block-start then ;

| And this fills in the commands array with the specific actions to execute:
' b< commands '< cells + !
' b> commands '> cells + !
' b+ commands '+ cells + !
' b- commands '- cells + !
' b. commands '. cells + !
' b, commands ', cells + !
' b[ commands '[ cells + !
' b] commands '] cells + !

| example:
|
| This is Wikipedia's HelloWorld implementation...
: hello-world " ++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>." bf ;

." Welcome to BrainF*ck for Reva.  Type 'hello-world' to run an example bf program." cr ;
