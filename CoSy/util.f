| Basic utilities 
| Author: Bob Armstrong / www.CoSy.com
| Reva's license terms also apply to this file.
| Should not require  CoSy obs .

cr ." | UTIL begin | "

alias: xeq execute
alias: |\/| | 
alias: |/\| |
alias: |>|  |

: :; ; 	| Do nothing . NOOP .

| =============================================== |
| redef  p:  and def  p[ . from Danny Reinholt
|  http://ronware.org/reva/viewtopic.php?pid=2454#p2454
| =============================================== |

| \/ |  Iverson logic | \/ | 
 
: =I ( n1 n2 -- flag )	| Original : =I =if 1 else 0 then ; 
	inline{ 3b 06 ad 0f 94 c0 0f be c0 } ; 
 | from Jukka , http://ronware.org/reva/viewtopic.php?pid=4613#p4613
 | the assembly:
 | cmp eax,[esi]   ; standard stuff
 | lodsd           ; ditto
 | sete al         ; sets al to 1 if zero flag set otherwise sets it to 0
 | movsx eax,al    ; expands al to eax filling the rest with zeros
 | 
 | was inline{ 3b 06 ad b8 0 0 0 0 75 01 40 } ;	
 | from Ron , http://ronware.org/reva/viewtopic.php?pid=4595#p4595
 | Annotated assembler from Cellarguy :
 | asm{
 |  cmp eax,[esi]	; compare TOS,NOS to set the zero clear flag
 |  lodsd			; poor-man's drop, or:
 |  				; 'I don't care what I pull into tos...  ( = drop )
 |  mov eax,00000000	; ...because I'm over-writing it anyway'  ( with 0 ).
 |  jnz .done       ; now we check that flag we set.
 |  inc eax			; if flag was set add 1 to the 0 and leave that ( -- 1)
 | .done:			; else just leave the 0 ( -- 0 )
 | } ;
 |
 | was : =I =if 1 ;; then 0 ; | Helmar 	2005-10-15 13:19:28 
 
: <>I <>if 1 ;; then 0 ;
: >I >if 1 ;; then 0 ;
: <I <if 1 ;; then 0 ;

: 0=I not negate ;	| similar to w32f 0= 
 
: M->I not 0=I ; 
| converts FORTH ( Moore ) logic ( TRUE = -1 , really <>0 ) to
| I-logic : Iverson logic ( TRUE = 1 )

: sn ( n -- -1 | 0 | 1 ) dup 0 >I swap 0 <I - ;	| sign of n
: <sn ( n0 n1 -- -1|0|1 )  - negate sn ;	| 1 iff n0 < n1 , -1 iff n0 > n1
: >sn ( n0 n1 -- -1|0|1 )  - sn ;	| sign of difference  
: >=0 ( n -- 0 1 ) -1 >I ; 	| returns 1 if n not negative
 
| /\ |  Iverson logic | /\ | 

|\/| Debugging & tracing fns	|\/|

: fnnm ( -- a n ) r@ ~debug.xt>near ; 	| returns name of executing fn

: pause ekey drop ;  

: DMP 32 dump ;

: .> dup . ;

: x$ base @ >r hex execute r> base ! ;		| Execute fn arg under hex base 
: $.> dup  : $. ." $" ['] . x$ ;

: 2.>  over . dup . ;  : $2.>  base @ >r hex 2.> r> base ! ;

: $.s  base @ >r hex .s r> base ! ;
: #. base @ >r decimal . r> base ! ;

: type>  2dup type ; 

: stkprmpt $.s cr " ok> " type ; | use : ' stkprmpt >defer prompt
  | set default prompt to show stack in hex . use  undo  to reset to original

| macro
| : x" p[ "  2dup type ]p ." | " p: eval ; 
| forth  
  
  
|/\| Debugging & tracing fns	|/\|

| =============================================== |

| \/ Miscellaneous		\/ 

: cells/ inline{ c1 f8 02 } ;inline 	| asm{ sar eax, 2 } | divide by 4 

: exist?  ' if ." yes " ;then ." no " ; 

: esi@ inline{ 8D 76 FC  89 06  89 F0 } ; 
  | lea esi,[esi-04]  mov [esi],eax   mov eax, esi 
  | esi contains the current stack ptr ,
  |  , ie , the address of the item which was ToS when it was called .
 
: esi! asm{ mov esi, eax } drop ; 
  | |(| esi@ esi! |)|  ends up doing nothing |

: ndrop 0 ?do  drop  loop ;	| should be optimized
| \/ | has some bug related to directory executing in ??? |
| : ndrop ( ... n -- drops n cells from stk ) 	| optimized from ' drop loop . 
| 	esi@ swap 1+ cells + esi!  ;
	| don't understand why :| : ndrop 1+ cells esi@ + esi!  ; |: doesn't work .

| : dup>r  inline{ 50 } ;inline  | from macoln . in  util/misc
  | http://ronware.org/reva/viewtopic.php?pid=4478#p4478 , from cellarguy
alias: >r> dup>r	| was : >r> dup >rr ;		| same as ... dup >r ... 

: rr@ 2 rpick ;

: 2>r >rr >rr ;		: 2r> rr> rr> ;	: 2r@ 1 rpick 2 rpick ;

: ii 3 rpick 2 rpick - ;	| or should the name be  I  ?
| index of loop accessed from inside executed function . Eg :
|  : tst { ii . } 5 0do dup execute loop drop ;  

: rp ( n a -- )		| pushes current val of var a on r-stack , sets to new val   
   dup r> swap @ >rr >r ! ;
   
: rP ( a -- ) r> rr> swap >r swap ! ;	| undoes  rp .
 
: stkp ( val var stk -- )	| like rp but pushes on named stack .
	 over @ swap push ! ;

: stkP ( var stk -- ) pop swap ! ; 


: @+  @ 1+  ;   | recommended by Charles Moore
                | http://www.ultratechnology.com/rmvideo.htm 990522

: @-  @ 1-  ;   | for symmetry

: @> ( a -- a n ) dup @ ; 

: !> ( n a -- a ) dup -rot ! ; 

: c+ cells + ;

: hw! ( n adr -- ) 2 + w! ; 	| store 16 bit value in hi word of cell
: hw@ 2 + w@ ; 

: w+! dup w@ rot + swap w! ;  ( n a -- )	| word  +!

: _0ws_ ( a n -- flag ( naked string contains no WhiteSpace ) 
|  Empty string returns "true" .	
	dup 0if drop true ;then 
	0do count ws?
	 if drop false unloop ;; then 
	loop drop true  ;


: str= cmp 0=I ;

: s>m ( n-items n addr - )              | move n cells from stack to memory
  sp 2 c+ swap rot cells move ;

| /\ Miscellaneous		/\ 

| =============================================== |

| \/ Auto Incrementers	\/

: @+!> dup @+ >r> swap ! r> ;     | auto increment counter
: @-!> dup @- >r> swap ! r> ;     | auto decrement

 | Better , post in(de)crement so current value is number items
 | and next index to be addressed .
: @>+! dup @ >r> 1+ swap ! r> ;     | auto increment counter
: @>-! dup @ >r> 1- swap ! r> ;     | auto decrement

|/\| Auto Incrementers	|/\|
| =============================================== |
|\/| CONSTANTS |\/|

$A constant LF
$D constant CR
$9 constant HT
32 constant BL		| blank
: BL= BL = negate ;

8 constant byte
4 constant cell 

$7FFFFFFF constant _n 	| `null ( missing value ) , NotANumber	
$7FFFFFFE constant 0I		| integer infinity . ( Largest pos Number )  
					| 2147483646  |   
0I 1 + constant 0N	| integer negative infinity 

: K*  $400 * ;
: M*  $100000 * ;

|/\| CONSTANTS |/\|

| =============================================== |

: on2> --ababc : on2 ( LA RA f -- LAr RAr )	| applies f to each LA and RA . 
| f must be monadic and return exactly 1 cell .
| on2> leaves items on stack . No ref chk .
 >r swap r@ execute swap r> execute ;

: c? ( a n x -- i ) | Index of first occurance of x in cell array  a n .
 | returns -1 if not found .
  swap 0 do over i c+ @ over =if 2drop i unloop ;then loop 2drop true ;    
 
: b? ( a n x -- i ) | Index of first occurance of x in byte array  a n .
 | returns -1 if not found .
  swap 0 do over i + c@ over =if 2drop i unloop ;then loop 2drop true ;    


: char parsews drop c@ ?literal ; 
| returns integer value of following character . eg | char A _i  |>| 65
| when compiling , appends char as literal .
| word same as GForth std  | 20171103 

| =============================================== |

| \/ Allocated buffer . Simple buffer and position value	\/

  0 value buf  variable bpos
: allocBuf ( n -- ) allocate to buf  bpos off ;

: bufcur ( -- adr ) buf bpos @ + ; 	| Current address in buf  

: bufinc ( n -- ) bpos +! ; 
	
| /\ Allocated buffer . Simple buffer and position value	/\


|	Create a cell array storing count in 0th cell 
: a[ create here dup , ;	| syntax : a[ name i1 , i2 , ... ]a
: ]a here over - cell / 1- swap ! ; 
  
: a? ( array n -- i ) | index of first occurance of n in cell "a[" array . 
	| This is intrinsically 1 origin and returns 0 if n not found .
  over @ 1+ 1 do over i c+ @ over =if 2drop i unloop ;then loop 
  2drop 0 ;

: ztype zcount type ;

| \/ Create a spooling space and fns for diverting  emit  and  type  \/
 
1 M* allocate value spoolbuf  
 ."  | SPOOL | ON" 
1 [IF]
 : spon  " " spoolbuf lplace 
	{ spoolbuf c+lplace } >defer emit 
	{ spoolbuf +lplace } >defer type ;
 
: spoff undo type undo emit ;
 
: (spool) ( fn -- a n ) 
  spon execute spoff spoolbuf lcount ;
 
|  [ELSE]

." | SPOOL | " 

: >spon ( buf -- ) >r> " " r@ lplace 
	{ rr@ c+lplace } >defer emit 
	{ rr@ +lplace } >defer type ;
	
| : spoff undo type undo emit ;
 
: >spool ( fn buf  --  ) 
   spon execute spoff  lcount ;

[THEN]

| /\ Create a spooling space and fns for diverting  emit  and  type  /\

| =============================================== |

| \/  A more sophisticated  catch  .  \/
 
variable thrown
a[ throwCodes THROW_BADFUNC , THROW_BADLIB , THROW_GENERIC , ]a
  
 make caught  ." Caught: " dup thrown ! throwCodes over a? if . 
  else ztype cr then ; 
 
| /\  A more sophisticated  catch  .  /\

| =============================================== |

| \/ augmented & trapped file fns \/

: fcreate ( a n -- fileid ) creat dup true =if
							z" file create error " throw then  ;

: foc ( a n -- fid ) | opens named file , creates if not existing .  
  2dup open/rw dup true =if drop fcreate ;then --c ; 

: fopen/r open/r dup true =if z" File open error " throw then ;
: fopen/rw open/rw dup true =if z" File open error " throw then ;


: fwrite ( adat ndat  afn nfn -- ) | opens file , writes & closes 
  fopen/rw >r> write r> close ;
  
: foverwrite ( a n afn nfn -- ) | opens file , writes & closes 
   2dup delete fcreate >r> write r> close ;

: dosslash ( a n -- a n )
| convert all / to \		| modified from lib/os/dir unixslash
   2dup 0do
		count '/ =if
			'\ over 1- c!
		then
	loop drop
	;

| /\ augmented file fns /\

| =============================================== |
| \/ additional time fns \/
 
	needs date/calendar with~ ~date
| "fixed" dates are days since 1 1 1 
 
: _time ( -- s m h ) time&date 3drop ; 
: _date ( -- d m y ) time&date >r >r >r 3drop r> r> r> ; 
 
: dtpk ( d m y -- yyyymmdd ) 100 * + 100 * + ; 
: dtupk ( yyyymmdd -- d m y ) 10000 /mod swap 100 /mod rot ; 
 
: date>fixed ( day month year -- fixed ) --bac gregorian>fixed ;
: fixed>date ( fixed -- d m y ) fixed>gregorian --bac ;
 
: ymd>fixed ( yyyymmdd -- fixed ) dtupk date>fixed ;
: fixed>ymd ( fixed -- yyymmdd ) fixed>date dtpk ;
 
: DoW ( day month year -- day-of-week ) date>fixed fixed>dow ;
| : toDoW here in~ ~priv GetLocalTime 4 + w@ ;	( -- today Day_of_Week )
: toDoW _date DoW ;
 
: dayname ( n -- a n )
   7 _mod 3 *
   z" SunMonTueWedThuFriSat" + 3 ;
 
: _ymdhms_ ( s m h d m y -- a n ) (.) pad place
   2 0do 2 '0 (p.r) pad +place loop 
   3 0do 2 '0 (p.r) pad +place loop pad count ;

: _ymd.hms_ ( s m h d m y -- a n ) (.) pad place
   2 0do 2 '0 (p.r) pad +place loop " ." pad +place   
   3 0do 2 '0 (p.r) pad +place loop pad count ;
 
: _ymdhm_ _ymdhms_ 2 - ; 
: ymdhm_ time&date _ymdhm_ ;
 
: _ymd.hm_ _ymd.hms_ 2 - ; 
: ymd.hm_ time&date _ymd.hm_ ;
 
: _DMymdhm ( s m h d m y -- a n )
| eg : Mon.Sep,20080929.1444 | result in  pad  so must be used immediately .
	3dup DoW dayname pad place " ." pad +place  
    over 1- monthname pad +place " ," pad +place 
   (.) pad +place
   2 0do 2 '0 (p.r) pad +place loop " ." pad +place   
   2 0do 2 '0 (p.r) pad +place loop drop pad count ; 
 
: _DMymd ( d m y -- a n ) 3dup DoW dayname pad place " ." pad +place  
   over 1- monthname pad +place " ," pad +place 
   (.) pad +place
   2 0do 2 '0 (p.r) pad +place loop  pad count ;    
 
: |=| " | ======================== |" ;
 
: dayln ( d m y -- a n ) "  " scratch place |=| scratch +place "  " scratch +place
   _DMymd scratch +place  
   "  " scratch +place |=| scratch +place scratch count ;    
 
: toDayln _date dayln ; 
 
: hm ( -- a n ) " " pad place time&date 3drop
   2 0do 2 '0 (p.r) pad +place loop drop
   pad count ; 
 
: |hm| ( -- a n ) " | " pad place time&date 3drop
   2 0do 2 '0 (p.r) pad +place loop drop
   "  | " pad +place pad count ; 
 
: daysTil gregorian>fixed today>fixed - ;
 
: daysdif ( d m y  d m y -- daysDif ) date>fixed >r date>fixed r> swap - ;
 
| /\ additional time fns /\
| =============================================== |

| Works w "case" system .
macro
: trueof p[ --aab execute if drop ]p ; 
forth

| =============================================== |
| Helmar's delete char and delete integer 
 
: dvc -rot over >r bounds tuck ?do
    2dup i c@ rot $.s of drop else swap c! 1+ then
   loop nip r@ - r> swap ;
 
: dvi -rot over >r bounds tuck ?do
    2dup i @ rot $.s of drop else swap ! 1+ then
   loop nip r@ - r> swap ;

| =============================================== |
| see http://ronware.org/reva/viewtopic.php?id=867
|  Takes function with syntax ( <word> -- ... ) and
|  provides the syntax ( a n fn -- ... ) . Eg : " over" ' see anfn .
 
: anfn ( arg[s] word -- word_on_<arg[s]> ) 
  xt>name "  " strcatf 2swap strcatf eval ;

| MATH \/ | =============================================== |

0 [IF]
: p2	( n -- next-higher-power-of-2 )		| for finding mem slots .
  | from  http://ronware.org/reva/viewtopic.php?pid=5865#p5865
  asm{
    shl eax, 1		; multiply by 2
    bsr eax, eax	; get exponent
  }
;

: 2^n? ( n -- bool )	| returns non-zero ( 1 or -1 ) if n power of 2 .
	| from Helmar ; http://ronware.org/reva/viewtopic.php?pid=5871#p5871
  asm{ 	
  cmp eax, 2
  jc .q
  lea ecx, [eax - 1]
  xor ecx, eax
  cmp eax, ecx
  sbb eax, eax
.q:
 } ; 

[THEN]

." | UTIL end | "

|||

