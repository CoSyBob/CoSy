| Simple Sudoku solver posted in comp.lang.forth by Jorge Acereda Macia
| http://tinyurl.com/yfjlnl
| Ported to Reva and further enhanced by Ron Aaron 22 Dec 2006
3 constant BLOCK_SIZE
BLOCK_SIZE BLOCK_SIZE * constant ROW_SIZE
ROW_SIZE ROW_SIZE * constant SUDOKU_SIZE

1 constant DIFFICULT
2 constant MEDIUM
3 constant EASY

0 value start
0 value end
create colbuf ROW_SIZE cells allot
create rowbuf ROW_SIZE cells allot
create blkbuf ROW_SIZE cells allot
: bounds ( a n ) over + swap ;
: wipe ( addr -- , erase buffer) ROW_SIZE cells 0 fill ;
: row ( index -- row , row for index) ROW_SIZE / ;
: col ( index -- col , col for index) ROW_SIZE mod ;
: blk ( index -- blk , blk for index)
    dup row BLOCK_SIZE / BLOCK_SIZE * swap col BLOCK_SIZE / + ;
: inc ( val index buf -- , accumulate value at index in buffer)
    >r >r dup if 1 swap 2* << then r> cells r> + +! ;
: markrow ( val index -- , mark value in row) row rowbuf inc ;
: markcol ( val index -- , mark value in col) col colbuf inc ;
: markblk ( val index -- , mark value in blk) blk blkbuf inc ;
: elem ( index -- val , element at index) cells start + @ ;
: mark ( val index -- , mark value in buffers)
    2dup markrow 2dup markcol markblk ;
: valid ( buf -- flag, check for valid combination in buffer)
    0 swap 8 cells bounds do
       i @ $AAAAAAAA and +
    loop not ;
: validate ( -- ok?, check for valid combination)
    colbuf wipe rowbuf wipe blkbuf wipe
    SUDOKU_SIZE 0 do i elem i mark loop
    colbuf valid rowbuf valid and blkbuf valid and ;
: back ( addr|0 -- addr|0 )
    dup if cell- then ;
: nomore ( addr|0 -- flag )
    dup if dup @ ROW_SIZE = else 1 then ;
: (solve) ( addr -- addr|0 )
    dup end =if drop 0 ;then
    validate 0; drop 
    dup @ if | Found a fixed number, skip it
          cell+ (solve) back
    else | Found a free number, try all the possibilities
          repeat  
			1 over +! cell+ (solve) back nomore 
		  not
		  while
          dup if dup off then
    then ;
: .sudoku ( addr -- , print board)
    to start
    SUDOKU_SIZE 0 do i elem . i col 8 = if cr then loop cr ;
: solve ( addr -- , solve sudoku)
    to start  start SUDOKU_SIZE cells + to end  start (solve) drop
    validate ;


needs random/gm
: empty? ( a -- flag ) @ 0 = ;
: remaining ( a -- n ) | get number of remaining squares
	0 swap 
	SUDOKU_SIZE 0do
		dup empty?	| count a' item
		if swap 1+ swap then
		cell+
	loop drop
	;
: 0fill ( a -- ) | replace all NUL characters with '0
." hi"
	SUDOKU_SIZE 0do
		dup @ 0if '0 over ! then
		1+
	loop drop
	;
: unused ( a -- ix ) | return index of random unused square
	repeat
		rand 0 max SUDOKU_SIZE mod tuck	| ix a ix
		cells over +				| ix a a'
		empty? if drop ;then		| ix a 
		nip
	again
	;
create possibles 9 cells allot
: randvalue ( a ix -- a ix v ) | look in the rows and columns to find possibles
	| prefill w/ possible values
	possibles ROW_SIZE 0do 
		i 1+ over ! cell+ loop drop
	2dup	| a ix a ix
	| iterate the row it's in:
	row ROW_SIZE * cells + |  a ix row-of-ix
		ROW_SIZE 0do dup i cells + @ 
			'0 - cells possibles + off
			loop drop | a ix
	| iterate the column...
	| find a value
	repeat
		possibles rand 0 max 9 mod cells + @
		dup not
	while
	;
| Fill one-quarter of remaining squares
: (gen) ( a -- )
	dup remaining 2 >> 
	0do
		| probe for an unused square
		dup unused | a ix
		| get a random possible valule
		randvalue	| a ix v
		| set the value
		>r cells over + r> swap !
	loop
	;
: rand1-9 ( -- n ) rand 0 max 9 mod 1+ ;

create sofar 10 allot
: get1-9 ( -- n )	
	rand1-9 | n
	| is it valid?
	dup sofar + c@ 0if
		| yes! flag it
		dup sofar + over swap c!
	;then
	| no, try again
	drop get1-9
	;
: fillblock ( a -- )
	| blank out the ones tried
	sofar 10 0 fill
	3 0do
		3 0do
			get1-9 over 
	.s cr
			!  cell+
		loop
		6 cells +
	loop drop
	;
: gen ( a difficulty -- ) |  create a new sudoku at the 81 bytes pointed to by "a"
	over SUDOKU_SIZE cells 0 fill	| create empty sudoku
	| fill in one block with numbers
	| there are 36 possible starting places
	over rand 0 max 36 mod
	| a diff a start
	|	over rand1-9 9 mod				| a diff a n
	6 /mod						| a diff a col row
	ROW_SIZE cells * + +			| a diff a[n]
|	ROW_SIZE cells * +			| a diff a[n]
	fillblock
	over .sudoku
	over solve 0if ." No solution" 2drop else over .sudoku then 
	;

: sudoku: create
	'; parse scratch lplace
	scratch lcount 0do
		count dup '0 '9 between
		if '0 - , else drop then
	loop  drop ;
sudoku: sudoku1
	100 804 020
	020 000 456
	003 205 000

	000 400 805
	789 050 000
	000 006 203

	801 000 700
	000 123 080
	205 000 009 ;


sudoku: s1
	100	890	000
	470	002	000
	006	500	020
	360	005	010
	000	070	000
	090	100	046
	020	004	800
	000	700	035
	000	068	009 ;
	

." Sudoku 1:" cr sudoku1 .sudoku ." Solution: " sudoku1 solve 

