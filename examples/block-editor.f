| vim: ft=reva
|
| blocks.rf: hood (i.e. blocks) operations

| Documentation:
| Creates a blocks-type operating environment so that you can edit
| and execute your code
|
| The "public" functions generally consist of verb-noun pairs
| verbs: b-blankify e-evaluate n-next p-previous r-read s-select t-type w-write g-getstring l-load c-save
| nouns: b-block h-hood l-lines
| Thus el means "evaluate lines"
|
| A "hood" (short for neighbourhood) is 64 contiguous blocks
|
| So, let's look at a typical sequence of operations:
| tb | print the current block - which should just be an empty screen
| 1 sb | lets work in block 1 (blocks start at 0) instead of block 0
| 0 il : hello ." hello world" ; | insert a line in the block
| tb | show the block, so that we can see what we've done so far
| eb | evaluate the block as if it were code
| hello | ta-da - it should type hello world
| wh | write out our "hood" to disk so that we can restore it next time
|    | using rh (for read hood)

| released into the public domain
| 22-mar-2006 mcarter created - www.markcarter.me.uk
| 25-mar-2006 mcarter version 1 released. Works with reva 6.0.3
| 01-jun-2006 mcarter added BLOCK
| 06-jun-2006 mcarter added bl?
| 04-jun-2006 danny   added gl ch lh - changed parse- to use /string

needs os/console
needs string/trim
needs util/eachline

1024 constant 1k
1k 64 * constant 64k
variable blocks 64k allot
0 value block# | current block number (for listing, editing, etc.)

: offset ( line# -- ) 64 *  block# 1024 * blocks + + ; 

| crblock - storage area for a block with cr-delimited endings
16 65 * constant 64+k
variable crblock 64+k allot
variable crline 65 allot
10 crline 64 + c! | store a terminating newline
: >crline ( line# -- ) offset crline 64 move ;
: crline> ( line# -- ) 65 * crblock  + crline swap 65 move ;
: >crblock 16 0 do i >crline i crline> loop ;

| augmentary functions
: parse- ( char <text> -- a n ) parse  1 /string ; | like parse

| ---------------------------------------------------------------------
| line operations

| -------------
| private words

: prepend ( line# -- ) 2 (.r) type space ; | print formatted line# 
: 2+ ( a b c -- a+b a+c) >r over >r + r> r> + ;

variable blf | used by bl?
: 0>blf 0 blf ! ; 
: 1>blf 1 blf ! ;

| ------------
| public words

: el ( line# -- ) offset 64 eval ; | evaluate line
: tl ( line# -- ) dup prepend offset 64 type cr ;
: bl ( line# -- ) offset 64 32 fill ; | blankify line
: bl? ( n -- f) | is line N of current block blank (f=true)?
    1>blf 
    offset 64 0 2+ do 
        i c@ 32 <>if 0>blf then
    loop 
    blf @ ; 

: il ( line# -- ) dup bl offset >r 13 parse- r> swap move ; | insert a line

| Return a string representing the line but without white space at the right end...
: gl ( line# -- a n )  offset 64 rtrim  ;


| ---------------------------------------------------------------------
| block operations

: block ( u -- a) | a-addr is the address of the first character of the block buffer assigned to mass-storage block u. 
    1k * blocks + ;
: tbi ." block: " block# . cr ; | type block information
: tb (  -- ) cls tbi 16 0 do  i tl loop ; | type out currently-selected block
: sb ( n -- ) to block# ; | select a block
: eb ( -- ) >crblock crblock 64+k eval ; | evaluate block
: bb ( -- ) 16 0 do i bl loop ; | fill a block with spaces
: nb ( -- ) block# 1+ to block# tb ; | next block
: pb ( -- ) block# 1- to block# tb ; | previous block

| ---------------------------------------------------------------------
| hood operations

variable bfname | blocks filename (default)
z" blocks.fb" bfname ! | set default value of bfname
-1 value bfid | hood fid
: ow bfname @ zcount creat to bfid ; | open blocks file for writing
: orb bfname @ zcount open/r to bfid ; | open blocks file for reading
: wh blocks 64k  ow bfid write bfid close ; | write hood to disk
: rh ( -- ) blocks 64k orb bfid read drop bfid close ; | read hood from disk
: bh ( -- ) blocks 64k 32 fill ; | blankify hood

| save the stuff as a usual source file
create nl 10 1,
: save-line ( handle line# -- handle )  over >r  gl  r@ write  nl 1 r> write  ;
: (ch)  ( a n -- )
  creat  dup -1 =if ." cannot open file!" cr drop ;then
    64k 64 /  | buffer size divided by line length  => nof. lines
    0 do
      i bl? not if  i save-line  then
    loop
  close
;
: ch ( <name> -- )  parsews  (ch)  ;

variable pos | current line number
: insert-line ( a n -- )  pos @ dup  bl offset  swap  move  pos @ 1 + pos ! ;

| load a normal text file into the neighbour hood
| Attention: All lines must have a length < 65 !!!
: (lh)  ( a n -- )
  bh
  slurp
  dup 0if drop ." cannot open file!" cr ;then
  0 pos !

  ['] insert-line eachline
;
: lh ( <name> -- )  parsews  (lh)  ;

bh
