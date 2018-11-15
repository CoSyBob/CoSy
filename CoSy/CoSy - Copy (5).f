| Main CoSy APL objects .
| Author: Bob Armstrong / www.CoSy.com
| Reva's license terms also apply to this file.

cr  ." Version 7 Stk bug : "  .s  cr 

." reset " reset cr

cr ." Ron Aaron's " .ver ."  | http://ronware.org/reva/" cr cr

with~ ~sys

needs debugger
needs os/shell needs os/dir needs os/fs

: osfix ( a n -- a n ) os if unixslash then ; 

needs util/locals
needs util/misc
needs choices

| needs util/case

needs math/floats 

with~ ~doubles with~ ~floats

needs math/mod	needs asm 

| ." big "
| needs math/big
| ." big " cr

context: ~CoSy  ~CoSy

: instdir appdir rem-separator split-path 2drop ;
| From Danny (?) to make loading directory independant 
| " REVAUSERLIB" instdir add-separator setenv

| " REVAUSERLIB" " CoSy\\" osfix setenv 

needs AltStackOps.f

." | started | "

needs util.f

needs CSauxstack.f

' stkprmpt >defer prompt
 | set default prompt to show stack in hex . use " undo prompt " to reset to normal

| \/ FOR DEBUGGING \/  ==================================== \/
 
defer AT+> 	make AT+> ; 		
defer FT+> 	make FT+> ;

alias: nakedallocate allocate 	alias: nakedfree free

: allocate prior allocate AT+> ;  ( bytes -- a )
: free FT+> prior free ;
 
| /\ FOR DEBUGGING /\  ==================================== /\

| DYNAMIC  \/ ================================================== \/
cr ." \\/ DYNAMIC \\/  "  $.s cr 

| The fundamental objects in CoSy are vectors ( lists ) and functions .

4 constant Head#

: (valloc) aligned dup allocate	dup rot 0 fill ;
: valloc ( n -- a ) Head# cells + (valloc) ;  ( bytes -- addr )
       | allocate n bytes  + Head# cells
       | ( type ; i# ( rho ) ; ( refs ; bits % cell ) ; meta )
       | 0 fills the allocated memory . This could be reduced to just the
       | head cells for speed .

: i# ( adr -- number_of_items ) cell+ @ ;	| "count" ; K # , like APL ` rho

: i#i# ( la ra -- la ra i# i# ) | leaves obs on stack since not ref chkt 
  over i# over i# ; 

: `BnR 2cell+ ;       | top half of 3rd cell is item size in bits
                      | bottom word of 3rd cell is reference count .
: bits! `BnR hw! ;
: bits@ `BnR hw@ ;

: Ibytes bits@ byte / ;	| bytes per item 

: mx 3cell+ ;	| not named  "meta" to avoid conflict w Reva help 	
: m@ mx @ ;	
: m! mx ! ; 
 
: m>ox 3cell- ;	| Meta to Object addr 


: vbody ( vadr - vBodyAdr ) Head# cells +  ;	| beginning of data 

: vbytes ( v -- n )		| total data bytes
   dup i# swap Ibytes * ;

: vsize ( addr -- n )	| # bytes in whole object , aligned
   vbytes aligned Head# cells + ; 

: van ( v -- a n )		| start-of-data , # bytes
   dup vbody swap vbytes ; 

: Vresize  ( Ob i -- Ob )	| resizes , trucates only , vector to n items .
  | used mainly for freeing waste space on large initialized buffer vecs .
  2dup swap cell + ! over Ibytes * Head# cells + resize
  ?dup 0if z" Vresize failed " throw then ;  

: ix    ( adr n -- adr of nth item in list ) | modulo indexing
  over i# ?dup 0if z" can't index empty " throw ;then 
   _mod over Ibytes * vbody + ;

| Objects are initialized with a reference count of 0 .
| In general functions decriment the reference count on exit , freeing
| the object if the reference count is 0 or less .
| If a fn calls other fns which check refs , or are operators which may
| be called with unknow fns , generally  refs+  must be called on entry
| to protect the objs for the duration of the fn , then refs- before exit .
| If the fn does not call any other ref smart fns , it can just use 
| ref0del before exit .
| See the decrementing fns right after the definitions of enclose .

: refs! `BnR w! ;
: refs@ `BnR w@ ;

: refs0 0 swap refs! ;		: refs1 1 swap refs! ;

( DEBUGGING @ ) 0 [IF]
: refs+ ( obadr -- )  dup ."  r+ " $. 
  `BnR 1 swap w+! ; 
[ELSE]
: refs+ ( obadr -- ) dup refs@ 1+ swap refs! ;
	| was | `BnR 1 swap w+! ; 
[THEN] 

: refs+> dup refs+ ;      ( obadr -- obadr )
: 2refs+  refs+ refs+ ;		| useful for LA RA 
: 2refs+> 2dup 2refs+ ;

: dup+ dup refs+> ;  | dup incrementing ref count 
 
: aba ( a b -- a b a ) | ref inced ` over 
  over dup+ ; 

| \/ \/ \/ LIST TYPES \/ \/ \/
| Mon.Feb,20080225 | I changed my original early APL like type labeling scheme
| for a cul-de-sac notion of direct addresses for type function . 
| Silly . Not stable from one compile to another .
|  Am thinking about going to simple index list in order of creation so can
| index to handler fns simply . But problems w that , too . 

| \/ nil \/ | 	This needs work .
| see  util  0I +1 constant _n		| _n is its own type 
 
_n constant TypeN
| create nil  TypeN , 1 , $00000001 , _n ,	| nil vector . |X only needs head X|  
|  nil nil meta!
 
create nil  TypeN , 1 , $00000001 , nil , _n ,	
 | nil vector . |
 
: _n; ( n -- n | _n &exit ) dup _n =if rdrop then ;
 
| /\ nil /\ | 	This needs work .

| \/ The most general type : CELL \/

0 constant Type0 

: cellVecInit ( n - objAdr )    | make header and allocate space for n cells
   dup cells valloc           ( n objAdr )
   dup Type0 swap !					| type 0
   dup cell+ rot swap !         | # of items
   dup cell byte * over bits!   | item size in bits 
   refs0 ;

: ic@ ( v i -- o ) ix @ ;	
: ic! ( o v i -- ) ix ! ;	| index fetch and store , cell 
 
 alias: ii@ ic@		alias: ii! ic!	| index fetch and store , integer

0 cellVecInit refs+> constant ev        | empty vector
 
: vdup ( adr -- newadr ) | returns copy of object  
  dup vsize dup allocate >r> swap move r@ refs0 r> ;

| \/ \/ \/ TYPES \/ \/ \/ |

alias: Type@ @		alias: Type! !  

: Type@@ : @@ ( la ra -- la ra la@ ra@ ) over @ over @ ;
  | fetches top 2 items , leaves items on stack

: typechk ( LA RA type -- flag ) 	| check both arg types match desired
	>r Type@ swap Type@ over = swap r> = = ; 

: simple? ( ra -- f ) Type@ M->I ;


| \/ INTEGER \/	
   
4 constant TypeI		| single cell INTEGER 

| { ." integer " } value TypeI

: int> dup : int TypeI swap ! ;	| convert type to int | int> returning

: intVecInit ( n - objAdr )		| make header and allocate space for int vec of length n
   cellVecInit int> ;			| integer vector type -1

 0 intVecInit refs+> value evI 	| empty integer vec . 

: _i ( cell -- 1_item_intvec ) 
   1 intVecInit >r> 0 ii! r> ;
 
: 2_i ( i i -- iv iv )  _i swap _i swap ;


: longer_ ( LA RA -- lengthOfLonger )	| Generally fns index shorter til longer  
   i# swap i# max ;
: longer longer_ _i ;

: shorter_ ( LA RA -- lengthOfShorter )	| Generally fns index shorter til longer  
   i# swap i# min ;
: shorter shorter_ _i ;


| \/ Enclosing - making general list from an atom \/   

: ?enc ( lst -- Iflag )         | return 1 if enclosed else 0
  @ 0=I ;

: 0encabort ( CSob -- CSob )    | Abort if not enclosed
  dup @ sn z" not enclosed " throw ;

: enc     ( CSob -- CSob )      | enclose
  1 cellVecInit swap refs+> over vbody ! ;
 
: encatom ( CSob -- CSob )      | Enclose iff not enclosed .
  dup @ if enc then ;       | An atom is anything other than a general list .
 
: enc>1 ( CSob -- CSob )        | Enclose iff i# > 1
  dup i# 1 <>if enc then ;

| \/ REF decrementing \/
| when the ref count of a general or enclosed list is decrimented ,
| each item must recursively be decrimented also .

( DEBUGGING @ ) 0 [IF]
: refs- ( obadr -- )	| decrements reference count , frees if 0 .
 dup ."  r- " $. 
  dup refs@ 1 -   
  dup 0 >if swap refs!
  else over ?enc
   if over i# 0 ?do over i ic@ refs- loop then
    drop free then ;      | decrement refs & free if 0
[ELSE]
: refs- ( obadr -- )	| decrements reference count , frees if 0 .
  dup refs@ 1 -   
  dup 0 >if swap refs! ;then
   over ?enc
   if over i# 0 ?do over i ic@ refs- loop then
    drop free ;      | decrement refs & free if 0
[THEN] 

: 2refs-  refs- refs- ;

: refs-ok> dup : refs-ok ( DEBUGGING @ ) 0 if dup ."  r- " $. then  
  `BnR -1 swap w+! ;	| sometimes need to decrement but not free .

: ref0del dup refs@ 0if refs- else drop then ;	| free if refs = 0 .
 | Thursday, June 02 2005 - 11:49 | I am concluding it is vital
 | for functions to free .. locally created obs w ref0del if
 | not returned as result , but leave input parameters alone .
 | input parameters consumed should be freed if 0 refs .
 
: 2ref0del ref0del ref0del ;

: onvbody ( LA~? RA fn -- res ) | executes fn on body of RA , 
   >r vbody r> execute swap ref0del ;

: onvan ( RA fn -- res ) | executes fn on van of RA , generally string 
  >r dup van r> execute swap ref0del ;

: sink refs- nil ;	| discard result , return nil 

| : ref0free refs@ 0if free then ;	| sometimes need to free w/o releasing
| 	| contents , eg , ' reverse . 

| \/ \/ | PARAMETER PUSHING | \/ \/ | | See p stack fns in CSauxstack.f 
 
 needs ParameterPushing.f

| /\ /\ | PARAMETER PUSHING | /\ /\ | 

: >value refs+> value ; 

ev refs+> value t0	| Temp handle holder . Frees old value when assigned new
: >t0 ( ob -- ob ) 
   t0 refs-  refs+> to t0 ;
 
: >t0> dup >t0 ;
   
ev refs+> value t1
: >t1 ( ob -- ob )      | Another Temp handle holder .
   t1 refs-  refs+> to t1 ;
 
: >t1> dup >t1 ;

| \/ Individual types \/ 

: Type@^ ( v -- v ) Type@ _i ;
: simple?^ simple? _i ; 

 0 _i refs+> constant i0 
 1 _i refs+> constant i1
-1 _i refs+> constant i-1 
   

|  \/ OPERATORS ON GENERAL VECS \/ 

: eachMcr ( CSob fn -- CSadr )	| `each Monadic cell resulting
   over refs+> vdup >aux		| fn must not change type .
   over i# 0 ?do over i ic@ over execute aux@ i ic! loop
   drop refs- aux> ;

: eachDcr ( LA RA fn -- R )		| each Dyadic on cells , resulting   
  -rot 2dup 2refs+> longer_ dup cellVecInit	| fn LA RA n r 
  swap 0 ?do 2 pick i ic@ 2 pick i ic@ 5 pick	| fn LA RA r LAi RAi
   execute over i ic! loop		| fn LA RA r 
  -rot 2refs- nip ;
    
: eachMir eachMcr int> ;
: eachDir eachDcr int> ;

defer aaply

macro
: i( 		| input integers up til " )i" -- IV |
  100 K* dup intVecInit 
   swap 0do parsews >single 
    if over i ic! 
   else 
    " )i" cmp if free z" integer input error" throw then	| i/o error 
    i Vresize leave 
   then loop ;
 
: i^ ( <int> -- int ) parsews >single if _i ;then
   2drop z"  not integer" throw ;  
forth

: m@^ m@ _i ;

: rho ( list -- #L ) dup i# _i swap ref0del  ;	
 | Same as i# but CoSy list result 

i( )i refs+> constant zild	| 0 iota 

1 [IF]
| integer dyadic funtions on simple lists eg | 5 _iota i( 1 -1 )i  +i `|
: +i ['] + eachDir ;	| add 2 integer vecs 
: -i ['] - eachDir ;	| subtract 2 integer vecs 
: *i ['] * eachDir ;	| * 2 integer vecs 
: /i ['] / eachDir ;	| div 2 integer vecs 
: _modi ['] _mod eachDir ;	| _mod 2 integer vecs 
: mini ['] min eachDir ;	| min 2 integer vecs . "and" on booleans . 
: maxi ['] max eachDir ;	| max 2 integer vecs . "or" on booleans .
 
: =i ['] =I eachDir ;	| = ( Iverson logic ) 2 integer vecs 
: <>i ['] <>I eachDir ;	| not equal ( Iverson logic ) 2 integer vecs 
: <i ['] <I eachDir ;	| < ( Iverson logic ) 2 integer vecs 
: >0i i0 : >i ['] >I eachDir ;	| > 2 integer vecs 
[THEN]

0 [IF]
: +i { ['] + eachDir } aaply ;	| add 2 integer vecs 
: -i { ['] - eachDir } aaply ;	| subtract 2 integer vecs 
: *i { ['] * eachDir } aaply ;	| * 2 integer vecs 
: /i { ['] / eachDir } aaply ;	| div 2 integer vecs 
: _modi { ['] _mod eachDir } aaply ;	| _mod 2 integer vecs 
: \/ : mini { ['] min eachDir } aaply ;	| min 2 integer vecs . "or" on booleans 
: /\ : maxi { ['] max eachDir } aaply ;	| max 2 integer vecs . "and" on booleans 

: =i { ['] =I eachDir } aaply ;	| = ( Iverson logic ) 2 integer vecs 
: <>i { ['] <>I eachDir } aaply ;	| not equal ( Iverson logic ) 2 integer vecs 
: <i { ['] <I eachDir } aaply ;	| < ( Iverson logic ) 2 integer vecs 
: >0i i0 : { >i ['] >I eachDir } aaply ;	| > 2 integer vecs 
[THEN] 

| : =c ['] =I each ;	| = ( Iverson logic ) 2 integer vecs 
| : <>c ['] <>I each ;	| not equal ( Iverson logic ) 2 integer vecs 

: absi ['] abs eachMir ;	| abs
: -0+i ['] sn eachMir ;		| sign 

: 0=i ( int -- bool )  i0 =i ; | essentially "not" 
: -1*i ( int -- negate ) i-1 *i ; 


: I. ( iv -- )	| output integer list .
 dup i# 0 ?do dup i ii@ . loop ref0del ; 

: $I. hex I. decimal ;

: ,I ( I0 I1 -- I0,I1 ) | catinates integer vecs .
  2dup i# swap i# + intVecInit >aux
  over dup i# 0 ?do dup i ii@ aux@ i ii! loop 
  i# over dup i# 0 ?do dup i ii@ aux@ 3 pick | I0 I1 I0# I1 I1@ aux 
    i + ii! loop 2drop 2ref0del aux> ;
  | It is so uncommon that I write something right the very first time that
  | I here make a note that I did just now  20060516.0105


: intVec ( n-items n -- oAdr )	| make int vec from n items on stack .
  dup intVecInit >r> vbody s>m r@ i# ndrop r> ; 

| \/ BYTE ( CHARACTER ) \/	  

1 value TypeC
| { ." character " } value TypeC 

: byteVecInit ( bytes - OA )    | make header and allocate space for n bytes
   dup 1+ valloc dup TypeC  swap !   ( n objAdr )  | type vec of 8 bit items
   dup cell+ rot swap !         | # of items | Plus one char for use with zt .
   dup byte over bits!          | item size in bits
   refs0 ;

: ib@ ix c@ ;		: ib! ix c! ;	| index fetch & store , byte

: _b 1 byteVecInit >r> 0 ib! r> ;

: _str ( a better name ) : str ( c-addr n -- OBadr )     | store a string
  dup byteVecInit dup >r        | c-ad n Oadr
  vbody swap move r> ;

: str< ( c-addr n -- str )     | store a string and free 
  --aab str swap free ;

: spool ( ... fn -- str ) (spool) _str ;
| moved from Furniture.f to as soon as definable . | 20180602 

macro
: "_ '" parse compiling? if (") ;then "" ; 	| 20180306
: s" p: "_ p: str ; 	| like Reva ' " but no escape .
: s/" p: " p: str ; 	| like Reav ' " . | NOT ANS s" I didn't know about . 
forth 

s" " refs+> constant zic 	| empty char string  
 
s"  " refs+> constant "bl 
 
s" ;" refs+> constant "; 
 
s"  " refs+> dup vbody CR swap c! constant "cr 
 
s"  " refs+> dup vbody LF swap c! constant "lf 
 
s"   " refs+> dup vbody dup CR swap c! LF swap 1+ c! constant "nl 
 
s"  " refs+> dup vbody HT swap c! constant "ht 

: ,s ( s0 s1 -- s0,s1 ) | catinates strings .
  2dup i# swap i# + byteVecInit >aux
  over dup i# 0 ?do dup i ib@ aux@ i ib! loop 
  i# over dup i# 0 ?do dup i ib@ aux@ 3 pick | see `,I 
    i + ib! loop 2drop 2ref0del aux> ;

: takeb ( iv n -- iv )             | APL take / reshape on bytes
  dup abs byteVecInit >aux
  dup 0 <if 0 swap else 0 then		| if n neg , 0 n  do 
  ?do dup i ib@ aux@ i ib! loop ref0del aux> ; 


| \/ SYMBOL \/ - Symbols are a special character type whose value equals their name .	

1 16 << 1+ constant TypeS
| { ." symbol " } value TypeS
| : symbol ;  ' symbol constant TypeS  | can't do in isolation 
 
: TypeS?_ Type@ TypeS =I ; 

| \/ Needs to eliminate blanks \/ |
: (sym) ( a n -- v )		| symbol count is 1 bits is  8 * chars max 8192 . 
   dup 1+ aligned valloc		| ( c-addr len addr )
   >r> TypeS over !		|  symbol type
   1 over cell+ !			| c-addr len addr  | # chars ( bytes ) stored
   over byte * over bits! refs0    | total bits in sym.
   r@ vbody swap move  r> ;
 
" "  (sym) refs+> constant `_	| empty symbol . Raises issue of notation of empty symbol don't have in K .

macro
: ` : sym ( <word> -- sym | )	| takes next word input and creates symbol 
  p: parsews (sym) compiling? if refs+> literal, then  ;
 
: `( 		| input symbols up til " )`" -- vecOfSyms |
  10 K* dup cellVecInit 
   swap 0do parsews 2dup " )`" cmp if (sym) refs+> over i ic!
    else 2drop i Vresize leave then loop compiling? if refs+> literal, then ; 
 
forth

: str~_ ( s0 s1 -- b )	| string/symbol match .
  2dup >r van r> van cmp 0=I --cab 2ref0del ;

: sym# (  -- #chars ) bits@ byte / ;

| \/ | Note : these fns operate on the object passed , not a copy . 
|  To emphasize that fact , no result is returned .
: sym>str ( sym -- ) TypeC over Type!  dup sym# over cell+ !  byte swap bits! ;   
 
: str>sym ( str -- ) TypeS over Type!  dup i# over bits@ * over bits! 
 1 swap cell+ ! ;
| /\ | See after def of ' rep for result returning |


: strym?_ ( obj -- rawBool )  | True iff obj a symbol or string. Does not refchk
	Type@ 1 and ; 

: sym?_ ( str -- rawBool ( string contains no WhiteSpace ) | No refchk .
	van _0ws_ M->I ;
 
: sym? ( str -- bool ( string contains no WhiteSpace )
	1p> sym?_ _i 1P> ;

: name?_ ( sym/str -- flag ) refs+> 
	dup strym?_ over sym?_ and swap refs- ;   

: symcat local[ sym0 sym1 | sym -- sym ] sym0 sym# sym1 sym# + 
   byteVecInit to sym 
  sym0 van  sym vbody  swap move
  sym1 van  sym vbody  sym0 sym#  + swap move 
  sym str>sym sym0 sym1 2ref0del sym ;   
 
: symdot local[ sym0 sym1 | sym -- sym ] sym0 sym# sym1 sym# + 1+ 
   byteVecInit to sym 
  sym0 van  sym vbody swap move
  sym1 van  sym vbody  sym0 sym#  + '. over ! 1+ swap move 
  sym str>sym sym0 sym1 2ref0del sym ;   


: stype ( str -- )	| string or symbol output  
	| dup @ dup TypeC = swap TypeS = or 0if drop z" not character " throw then 
	dup van type ref0del ;

: strout ( StrAdr chr -- )      | output various labeled string types 
   emit ." \" " stype ." \" " ;
 
: C. ( StrAdr -- ) ( 's strout ) stype ;   | output string

: C.cr C. cr ;

: S. '` emit space stype ;		| output symbol
 

| \/ FLOAT \/ | ===================== | 

round.up		| Set FPU rounding mode 

10 constant TypeFl 
| { ." float " } value TypeFl

: floatVecInit	( n - objAdr )	| make header and allocate space for float vec of length n
   dup floats valloc 	( n objAdr )
   dup TypeFl swap !				| type 0
   dup cell+ rot swap !			| # of items
   dup b/float byte * over bits!   | item size in bits 
   refs0 ;

: if@ ix f@ ;		: if! ix f! ;	| index fetch & store , float
 
: _f : _fv ( float -- fv )  1 floatVecInit >r> 0 if! r> ; 	| 
 
: 2_f _f _f swap ; 

1. _f value f1. 	-1. _f value f-1.

| like  >float  but converts integer strings 
: >>float ( a n - see >float )  >float if true 
	else >single if s>f true else false then then ; 
 
| : ^>float  >>float _f onvan ;
 
: ^>float { >>float if _f ;then z" not number " throw } onvan ;
 
: f( 	| input floats up til " )f" . return FV .
  100 K* dup floatVecInit	| I'm trusting that resize really frees unused mem
   swap 0do parsews >>float 
     if dup i if!  
     else 
      " )f" cmp if free z" not number " throw then 	| i/o error 
      i Vresize leave
	 then loop ; 

| /\ FLOAT /\ | ===================== | 

: v#@ ( v -- count&type )  dup i# swap @ ;  

: VecInit  ( n type -- vec )
  case
   Type0  of cellVecInit	endof
   TypeI  of intVecInit		endof
   TypeC  of byteVecInit	endof
   TypeFl of floatVecInit	endof
   drop cellVecInit 
  endcase ;

cr ."  \\/ each \\/ " $.s cr
| ======================================== |

: eachMfr ( RA fn --  r ) 
  over refs+> i# dup floatVecInit >aux
  0 ?do over i if@ dup execute aux@ i if! loop
  drop refs- aux> ; 
 
: eachMfir ( RA fn --  r ) 
  over refs+> i# dup intVecInit >aux
  0 ?do over i if@ dup execute aux@ i ii! loop
  drop refs- aux> ;   
 
: eachDfr ( LA RA fn -- r ) 	| each Dyadic on floats , resulting 
  -rot 2dup 2refs+> longer_ dup floatVecInit >aux
   0 ?do over i if@ dup i if@ 2 pick execute aux@ i if! loop
   2refs- drop aux> ; 
 
: eachDfir ( LA RA fn -- r ) 	| each Dyadic on floats , cell resulting 
  -rot 2dup longer_ dup intVecInit >aux
   0 ?do over i if@ dup i if@ 2 pick execute aux@ i ii! loop
   2ref0del drop aux> ; 

: takef ( fv n -- fv )             | APL take / reshape , float
  dup abs intVecInit >aux
  dup 0 <if 0 swap else 0 then		| if n neg , 0 n  do 
  ?do dup i ii@ aux@ i ii! loop ref0del aux> ; 

: _iota ( n -- adr )
  dup intVecInit
  dup vbody rot                |  adr bodyadr n
  0 ?do i over i c+ ! loop
  drop ;

| \/ | Float fns | \/ | 
 
: +f ['] f+ eachDfr ;	| add 2 float vecs 
: -f ['] f- eachDfr ;	| subtract 2 float vecs 
: *f ['] f* eachDfr ;	| * 2 float vecs 
: %f ['] f/ eachDfr ;	| div 2 float vecs 
: ^f swap ['] f^ eachDfr ;	| LA ^ RA . Note arguments swapped from Intel order to standard 
 
: 1%f ['] 1/f eachMfr ;
: floorf ['] ffloor eachMfr ; 	| 3.14 -> 3.00  
: absf ['] fabs eachMfr ; 		| -n.m -> n.m 
: sqrtf ['] fsqrt eachMfr ; 
: fracf ['] ffrac eachMfr ; 
: lnf ['] fln eachMfr ; 	: l10f lnf 10. _f lnf %f ; 


: f^2 fdup f* ; 	| not defined in lib/math/floats .
 | Much more efficient than { rep *f }  . Just 2 x87 instructions .
: ^2f ['] f^2 eachMfr ; 
 
: =f { f= M->I } eachDfir ;	| = ( Iverson logic ) 2 float vecs 
: <f { f< M->I } eachDfir ;	| < ( Iverson logic ) 2 float vecs 
: >f { f> M->I } eachDfir ;	| > ( Iverson logic ) 2 float vecs 

: fmin fover fover f< if fswap then ; 	| not defined in lib/math/floats 
: fmax fover fover f> if fswap then ; 	| not defined in lib/math/floats 

: minf ['] fmin eachDfr ; 	| 
: maxf ['] fmax eachDfr ;

: F. ( fv -- ) 
  dup i# 0 ?do dup i if@ f. loop ref0del ;  

: i>f ( intVec -- floatVec ) 	| convert int to float 
  dup i# dup floatVecInit temp !
   0 ?do dup i ic@ temp @ i ix swap s>f f! loop 
  ref0del temp @ ; 
 
: f>i ( floatVec -- intVec ) ['] f>s eachMfir ; 

| \/ OTHER \/	 
0 [IF]
$4d7e6d value TypeInterval		| " m~M" ( min to Max )
: interval ( LA RA -- interval )  | really just a pair of endpoints
  | w b useful to optimse indexing . 
  2 intVec dup TypeInterval swap ! ;
[THEN]  

cr ."  \\/ raw fn types \\/ " $.s cr
| \/ RAW FN TYPES  \/ \/ \/

$10000 constant TypeV 		| verb
$20000 constant TypeA 		| Adverb
$40000 constant TypeFv 		| FORTH verb

|  Fns have no names just symbols associated thru dictionary .

: v" p: " str TypeV over ! ;
: v. 'v strout ; 

: a" p: " str TypeA over ! ;
: a. 'a strout ;

: f" p: " str TypeFv over ! ;
: fv. 'f strout ;	| must  be "fv" because "f." is floats .


| ======================================== |

choices: ifetch	( vec idx type -- val )
 ' ic@ Type0 choice		' ii@ TypeI choice
 ' ib@ TypeC choice		' if@ TypeFl choice
 ' ic@ default 

: i@ ( a i -- item ) 
  over @ ifetch ;

: i@i@ ( l r i -- lr rr ) >r swap r@ i@ swap r> i@ ;    

: 0i@ dup 0 i@ swap ref0del ;	

: rplc ( new p0 -- )   | ref- and replace pointer at ' p0
  dup @ refs- swap refs+> swap ! ;
 | swapped order : over @ refs- refs+ swap ! 

macro  : => ( noun <obj> -- ) p: addr rplc ;   forth 

: i0! over refs+ ic! ;  

choices: istore
 ' ic! Type0 choice		' ii! TypeI choice 	| c for "cell"
 ' ib! TypeC choice		' if! TypeFl choice
 ' ic! default 

: i! ( item a i -- ) 
  over @ istore ;


: i_ dup 0 i@ swap ref0del ;  | raw first item of list . 

: iota  0i@ _iota ;

: t@ ( lst idx -- val type ) over @ >r> ifetch r> ; 

: >^ ( val type -- 1#List ) 1 swap VecInit >r> 0 i! r> ;   

: ^@ ( lst idx -- ^itm ) t@ >^ ;

: s>iv ( . . . n -- iv ) | makes int vec of top n items on stack 
  intVecInit >aux>  i# 0 ?do aux@ i ii! loop aux> ;

| : v>s ( v -- i0 i1 .. in ) | pushes int or char v onto stack .

: v>s ( v -- i0 i1 .. in ) | pushes int or char v onto stack .
  >aux> i# 0 ?do auxx@ remains i@ loop auxdrop aux> ref0del ; 

| NOTE : pushes in reverse order so inverse to  ' s>iv . 

: s_n? ( . . _n . . . -- . . _n . . . n )	| Returns depth to first
		| occurance of nil ( _n ) . Returns  depth  if no _n . 
   depth 0 ?do i pick _n =if i unloop ;then loop depth ;

: s_n>iv ( . . _n . . . -- iv )  s_n? s>iv nip ;
| makes int vec of stack down to occurance of _n

: v?refs+ ( v -- ) | increment ref count of each item of enc list .
   dup @ 0if dup i# 0 ?do dup i i@ refs+ loop then drop ;

: s_n>ev ( . . _n . . . -- iv )  s_n>iv dup Type0 swap ! dup v?refs+ 
   | makes enclosed vec of stack down to occurance of _n
  ;

0 [IF] 
choices: plus
 ' +i
cr cr  ." 0010 " ." Stk : "  $.s  cr cr 
: +I ( LA RA -- sum ) 
  over @ over @  2dup 
   =if drop TypeI =if +i ;
[THEN]

| cr cr  ." 0000 " ." Stk : "  $.s  cr cr 

choices: out
 ' I. TypeI choice		' F. TypeFl choice
 ' C. TypeC choice
 :: ref0del z" nonce " throw ; default 
 
: O dup @ out ;

cr ."  \\/ ops \\/ " $.s cr
| \/ OPERATORS   \/ ========================================== \/

| cr cr  ." 0000 " ." Stk : "  $.s  cr cr 

: eachM ( v fn -- ) over refs+> i# 0 ?do over i i@     | CSob fn item
   over execute loop drop refs- ;
| primative `each Monadic , no result , eg , printing | 

: ^eval ( str -- ? ) >r> van eval r> ref0del ;

| a[ byteFns  ]a

a[ intFns ' + , ' - , ' * , ' / , ' _mod , ' = , ' =I , ' and , ' or , ' <>I , ' >I , ' <I , ' 0=I , ' negate , ' @ , ' i# , ' i@ , ' i! , ' refs@ , ' bits@ , ]a

a[ floatFns ' f+ , ' f- , ' f* , ' f/ , ' f= , ' fsin , ' fcos ,
   ' ftan , ' fatan , ' fnegate , ' f0 , ' f1 , ' fpi , ' fabs , ' fsqrt ,  ]a

: verb? dup _n =if false ;then ( Type TypeV TypeA TypeFv or or ) $70000 and ;  
: noun? verb? not ; 

: fntype ( fn -- type )		| result type
   dup intFns swap a? if drop TypeI ;then  
   dup floatFns swap a? if drop TypeFl ;then
   drop Type0 ;		| if none of the above assume cell   

." ---- " cr

: >_ ( disclose  non-nested  and free if 0 refs ) dup 0 i@ swap ref0del ;
 
: dsc ( obj -- first_item ) | returns 0th item , | 20130923.230527 
  dup i# 0if ;then  	| If empty , just return 
  dup @ 0if dup 0 i@ refs+> (  to protect result from freeing if nested ) 
      swap ref0del dup refs-ok ;then  
    1 over @ VecInit >aux dup 0 i@ aux@ 0 i! ref0del aux> ;	
    | otherwise , just returns . 20090809.1347 

: _at\ ( Lst idx -- items ) _i    : at\ ( v i -- v )  
| fundamental indexing fn . Always returns enclosed list of enclosed item
   dup i# --abca Type@ VecInit >aux>  i#		| v r #
   0 ?do 2dup i i@ i@ aux@ i i! loop
   aux@ v?refs+ 2ref0del aux> ;

: _at _i : at ( v i -- v ) | discloses if singlton index . 
| no diference on simples . Try | Dnames 1 _at\ | vs | Dnames 1 _at | 
    dup i# >r at\ r> 1 =if dsc then ; 

: _at! _i : at!  ( v0 v i -- ) | insert elements of v0 at locations i in v 
  | NB : This will change  v  in the dictionary in which it is defined 
  | If you want a new copy use ` duplst first .
	swap >aux 2p ( L@ lst cr R@ lst cr aux@ lst cr )
	aux@ Type@ 0if L@ i# 0do L@ i i@ aux@ R@ i i@ ix rplc loop 2P auxdrop ;then
     R@ i# 0do L@ i i@ aux@ R@ i i@ i! loop 2P auxdrop ;

: 'm : eachM> ( RA fn -- R )	| each monadic
   over TypeFl =if eachMfr ;then		| Floating , sui generis 
   over i# over fntype VecInit >aux		| RA fn 
   over refs+
	aux@ i# 0 ?do over i i@ over execute aux@ i i! loop
	aux@ v?refs+ drop refs- aux>  ;

: each ( LA RA fn -- R )
   over Type@ TypeFl =if eachDfr ;then 	| Floats are sui generis
   --abcab 2refs+> longer_ over fntype VecInit >aux>
   i# 0 ?do 2 pick i i@ 2 pick i i@ 2 pick execute aux@ i i! loop
   aux@ v?refs+  drop 2refs- aux> ; 
 
: 'L : eachleft ( LA RA fn -- R )	| execute fn using RA over each item of LA
   dup fntype TypeFl =if z" nonce " throw ;then 	| Floats are sui generis
   --abcab 2refs+ 2 pick i#  over fntype VecInit >aux>
    i# 0 ?do 2 pick i i@ --abcab execute refs+> aux@ i i! loop
	drop 2refs- aux> ;
 
: 'R : eachright ( LA RA fn -- R )
  | iterates over raw items of RA . result of fn must be a CoSy object 
  >r 2p r> | fntype TypeFl =if z" nonce " throw ;then 	| Floats are sui generis
    R@ i# l0@ fntype VecInit 
    dup i# 0 ?do L@ R@ i i@ l0@ execute refs+> l1@ i i! loop 
   l1@ 2P> ;

| \/ |  Atomic Apply operators . Apply verb to simple leafs of noun  | \/ | 
| see | 20180226 | 
: aaplym ( n v -- r ) 
   swap 1p 
   R@ Type@ 0if  | ." ( BRANCH ) " 
      R@ i# cellVecInit >aux>		| Res 
    	i# 0 ?do R@ i i@ L@ ( $.s cr ) aaplym refs+> aux@ i i! loop
    	1P drop aux>		| 
	else | ." ( LEAF ) " | 
	 R@ L@ ( $.s cr ) execute 1P> nip 
    then ;
 
:: ( aaply LA RA fn -- r ) 
   --cab 2p 
   R@ Type@ 0if
     L@ Type@ 0if | ." ( BRANCH ) both nested "  
       LR@ longer_ cellVecInit >aux>
        i# 0 ?do LR@ i i@i@ 3 SF@ aaply refs+> aux@ i i! loop aux> 
   	  else | ." ( L LEAF  R NEST ) " 
   	  R@ i# cellVecInit >aux> 
   	   i# 0 ?do L@ R@ i i@ 3 SF@ aaply refs+> aux@ i i! loop aux> 
   	  then
    else ( R LEAF )
   	 L@ Type@ 0if | ." ( R LEAF L NEST ) " 
   	  L@ i# cellVecInit >aux> 
   	   i# 0 ?do L@ i i@ R@ 3 SF@ aaply refs+> aux@ i i! loop aux> 
   	  else | ." ( both LEAF ) "  
   	   LR@ 3 SF@ execute 
	  then
	then 
	2P> nip 
	;
 is aaply

: ^= ( LA RA -- Bool ) ['] =i aaply ;
: ^+ ['] +i aaply ;

variable indentv   : indent indentv @ spaces ;
: lstitm  indent execute cr ;
: lst ( list -- )	| display the contents of a nested list   
	 dup @ 0if ( LIST ) indent ." ( " cr indentv ++ ['] lst eachM ."  )" indentv -- ;then   
	 dup @ TypeI  =if ['] I. lstitm ;then
	 dup @ TypeC  =if ['] C. lstitm ;then
	 dup @ TypeS  =if ['] S. lstitm ;then
	 dup @ TypeFl =if ['] F. lstitm ;then
	 dup @ TypeV  =if ['] v. lstitm ;then
	 dup @ TypeA  =if ['] a. lstitm ;then
	 dup @ TypeFv =if ['] fv. lstitm ;then
	 dup @ _n     =if drop indent ."  _n " cr ;then
     drop indent ." ( " ." nonce " ."  )" cr ;
 
: o ( list -- list ) | show CoSy obj leaving unchanged . useful for debugging
	dup refs+> dup lst refs-ok ;
 
: oo over o drop o ; 	| show top 2 items on stack . 
 
: fmt ['] lst spool ; 	| capture output of ' lst . 20180602

|  Best to handle typing outside of loops .

: acrossY  local[ proto obadr fn | n r -- res ]    | dYadic result returning "/"
   obadr i# to n  obadr vbody to obadr  proto to r
   n 0 ?do r obadr i c+ @ fn execute to r  loop
   r ;

: acrossI  ( RA fn -- r )		| result returning "/" on integer lists 
   over 0 i@ -rot		| r RA fn   
   over i# 
     1 ?do 2 pick 2 pick i i@ 2 pick execute 2 put  loop
   drop ref0del _i ;   

: acrossYf  ( f:r0 RA fn -- r )	| result returning "/" on float lists 
	 over refs+> 	| LA is initial result ( identity element ) on f stack  	  
    i# 0 ?do over i if@ dup execute loop
   drop refs- 1 floatVecInit dup 0 if! ;

: acrossf  ( RA fn -- r )	| result returning "/" on float lists 
	over i# 0=I z" nonce : empty , needs prototype " * throw 	
    over refs+> dup 0 if@
    i# 1 ?do over i if@ dup execute loop
   drop refs- 1 floatVecInit dup 0 if! ;

: acrossC  ( RA fn -- r )	 | result returning "/" on cell lists 
   over 0 i@		| RA fn r	| bombs on empty arg . use acrossYc		 	  
   2 pick i# 
     1 ?do 2 pick i i@ 2 pick execute loop
   >r drop ref0del r> ;
 
: Y./ : acrossYc  ( LA RA fn -- r )	| result returning "/" on cell lists 
	rot		| RA fn r			| LA is initial result 	  
   2 pick i# 
     0 ?do 2 pick i i@ 2 pick execute loop
   >r drop ref0del r> ;

: across  ( RA fn -- r ) | result returning "/" |
   over i# 0if drop ;then       |  empty simply returns itself 
   over i# 1 =if drop dsc ;then | 1 item discloses ( ala K )
   dup fntype TypeFl =if acrossf ;then
   over refs+> 0 i@ >aux
   over i# 1 ?do aux> 2 pick i i@ 2 pick execute >aux loop
   drop refs- aux> ;

: acrossN ( RA fn -- r ) $.s  swap 1p $.s cr 
   R@ i# 0if ." empty  " $.s cr drop R@ 1P> ;then 	| if empty , just returns .
  R@ Type@ case $.s cr 
   Type0 $.s ."  | " of $.s cr R@ swap across endof  
   TypeI  of ['] + acrossI endof 
   TypeFl of ['] f+ acrossf	endof 
   drop refs- z" invalid type " throw
  endcase 
   $.s cr 1P> ;   

: _./  ( LA fn -- r ) | result returning "/" , "across" on naked fns
| If empty or singlton , simply returns arg . 
   over i# 2 <if drop ;then
   >aux   refs+> >aux> 0 _at\ aux@ 1 _at\ auxx@ execute 
   aux@ i# 2 ?do aux@ i _at\ auxx@ execute loop
   aux> refs- auxdrop ; 
 
: ./ : across^  ( RA fn -- r ) | result returning "/"  on CoSy obs
   over i# 0if drop ref0del z" nonce : empty , needs prototype " throw ;then 
   over refs+> >r> i0 at\ r> i1 at\ --abca execute >aux
| aux@ . ." here " $.s cr
   over i# 2 max 2 ?do aux> 2 pick i _at\ 2 pick execute >aux loop
   drop refs- aux> ;

: +/ ( RA -- r ) 
  dup Type@ case
   Type0  of drop refs- z" ( nonce ) " throw	endof 
   TypeI  of ['] + acrossI endof 
   TypeFl of ['] f+ acrossf	endof 
   drop refs- z" invalid type " throw
  endcase ;

| -------- 

: scanf  ( RA fn -- r )	| result returning "\" on float lists 
	over i# 0=I z" nonce : empty , needs prototype " * throw 	
    over refs+> i# floatVecInit >aux 
	over 0 if@ aux@ 0 if! 
    over i# 1 ?do aux@ i 1- if@  over i if@  dup  execute  aux@ i if! loop
    drop refs- aux> ;

: scan ( RA fn -- r ) | result returning "\"
	over i# 0=I z" nonce : empty , needs prototype " * throw 
	dup fntype TypeFl =if scanf ;then
	over refs+> i# over fntype VecInit >aux 
	over 0 i@ aux@ 0 i! 
    over i# 1 ?do aux@ i 1- i@  2 pick i i@ 2 pick execute aux@ i i! loop
    drop refs- aux> ;

: scanI  local[ RA fn | R -- R ]     | raw scan over interger vecs .
  RA i# intVecInit to R  RA 0 i@ R 0 i!
  RA i# 1 ?do R i 1- i@  RA i i@ fn execute R i i! loop
  RA ref0del  R ;
 | done | NB : it might be possible to move this before , and use it in  refs- .

: _delta ( RA fn -- V )		| K ': . Applies fn between each pair of RA
	over i# 0if z" length 0 " throw then
	over i# 1- over fntype VecInit >aux
	aux@ i# 0 ?do over i 1+ i@ 2 pick i i@ 2 pick execute aux@ i i! loop
	drop refs- aux> ;
 
| -------- 

: _f? ( lst RA boolF -- index | _n )
	| index of first item in LA on which { RA boolF }
	| returns true . Returns _n if not found . 
	| This is a generalization of APL's dyadic iota , and
	| K's ? both of which are functions which assume the boolF : ` = | 
   >aux 2refs+> over
    i# 0 ?do over i i@ over aux@ execute		 
     if auxdrop 2refs- i unloop ;then loop
	auxdrop 2refs- _n ;
 
: f? ( lst RA boolF -- index )
	| index of first item in LA on which { RA boolF }
	| returns true . Returns LA rho ( bad idea : Returns _n ) if not found . 
	| This is a generalization of APL's dyadic iota , and
	| K's ? both of which are functions which assume the boolF : ` = | 
   >aux 2p
    L@ i# 0 ?do L@ i _at R@ aux@ execute i_ 
     if auxdrop 2P i _i unloop ;then loop
	auxdrop L@ rho 2P>  ;  

| more efficient search for 1st occurance of string in string | 20180315
: ss1st ( s0 s1 -- idx ) 2refs+> 2dup >r van 
	--aab r> van search 2drop swap - _i --cab 2refs- ; 
| thought it would be useful in making | : tst f( 1 0 )f ; | work .  

0 [IF]
: _f? ( lst RA boolF -- index | _n )
	| version for naked RA 
   >aux over refs+ over i# 0 ?do
     over i i@ over aux@ execute		 
    if auxdrop drop refs- i unloop ;then loop
	auxdrop drop refs- _n ;  

: f?m ( lst rawBoolF -- index )
	| index of first item in RA on which ' boolF 
	| returns true . Returns RA rho if not found . 
	| This is a generalization of APL's dyadic iota , and
	| K's ? both of which are functions which assume the boolF : ` = | 
   >aux 1p
    R@ i# 0 ?do R@ i i@ aux@ execute 
     if auxdrop 1P i _i unloop ;then loop
	auxdrop R@ rho 1P>  ;  
[THEN]

| /\ OPERATORS /\ ============================================ /\

." /\\ ops /\\ " cr

." \\/ fns \\/ "  $.s cr

| \/ FUNCTIONS \/ ============================================ \/

: 0=L ( iLst -- iLst ) ['] 0=I  eachM> ; | Iverson "not" on list 

: -1* ( nv -- nv ) dup @ TypeFl =if -1. _f *f ;then
   dup @ TypeI =if i-1 *i ;then
   ref0del z" must be numeric " throw ; 

: thru ( LA RA -- IV )		| vector of integers from LA to RA - 1 .
   2p> swap -i iota L@ +i 2P> ;
  | was til 20141221.2349 | 2dup swap -i _iota nip swap _i ['] + each ; 

: apvi ( start increment n -- a ) iota *i +i ;
	| IBM's Arithmetic Progression Vector . Affine transform of  iota n .
 
: _apv _i : apv ( start increment  n -- a ) iota i>f *f +f ; | floating 

: mem>iv ( adr n -- obadr )     | copy n cells from memory to IV
  dup intVecInit >r> 0 ix swap cells move r> ;

        | : si ( n - i# n )  0 ?do i loop ;    | Stack Iota ; 

: &  ( I0 -- I1 )   | for each item of I0 return val n reps of corresponding
| index .  Example |  i( 0 0 0 1 0 1 0 3 1 )i & |>| 3 5 7 7 7 8  |
    	| ( Arthur Whitney def of ' where , and even his symbol )
        | example of use of extended def ( from Marco Pescosolido , soln to EE McDonnell's
    	|  K finger exercises # 39  )
    	|  x[|>&y]  reverse subsets , EEMD : "infixes" , of lengths  y  of list x .
	refs+>
    dup @ TypeI <>if refs- z" & : arg must be integer " throw then    
    dup i# 0if refs- zild ;then
    dup ['] + across  -1 >aux  intVecInit >aux
    dup i# 0 ?do dup i i@ 0 ?do j aux@  auxx> 1+ >auxx>  i! loop
			  loop refs- aux> aux> drop  ;

: reverse ( v -- r )	| 0 1 2 3 -> 3 2 1 0
  dup v#@ VecInit		| v r
  dup @ if ( SIMPLE ) dup i# 
    over @ TypeFl =if 0 ?do over i 1+ negate i@ dup i i! loop 
     else 0 ?do over i 1+ negate i@ over i i! loop then
	else 
   ( LIST ) dup i# 0 ?do over i 1+ negate i@ refs+> over i i! loop then
  swap ref0del ;

: (' _n ; 
 
help dup 	| totally bizarre . need invocation of ' help between defs of 
| ' (' and ' ')  or help  bombs ! | 20180502.1857 
| see Sat.May,20180505 
 
: ') s_n>ev reverse ; 	| make list of executed items . see 20180420
| eg: | ('  20180406.0724 _f  ` PSBT  ` BH  165.54 _f  s" auto"  ') 

: rotate >_ : _rotate ( v n -- v )		| i( 0 1 2 3 4 )i 2 -> i( 2 3 4 0 1 )i 
   >aux dup v#@ VecInit
    dup @ if ( SIMPLE ) dup i#
     over Type@ TypeFl =if 0 ?do over i aux@ + i@ dup i i! loop 
               else 0 ?do over i aux@ + i@ over i i! loop  then 
	 else ( LIST ) dup i# 0 ?do over i aux@ + i@ refs+> over i i! loop then
   auxdrop swap ref0del ;

: sublist ( lst i0 i1 -- lst )	| returns substring from i0 to i1 - 1
  2dup >if Head# drop z" sublist : i0 must not be greater than i1 " throw ;then 
  over - >aux> 2 pick @ VecInit >aux	| lst i0
  over swap ix aux@ vbody auxx> aux@ Ibytes *  move
  aux@ v?refs+ 
  | aux@ @ 0if aux@ i# 0 ?do aux@ i i@ refs+ loop then 
  ref0del aux> ;

: _take ( v n -- r )		| APL take / reshape , just lists 
   ?dup 0if 0 over Type@ VecInit swap ref0del ;then | n = 0 , return empty 
	over i# 0if drop ref0del fnnm  "  : nonce : empty , needs prototype "
	 		strcat zt throw ;then 
   dup abs 2 pick @ VecInit >aux 
   over i# aux@ i# <if		| n > # v
     dup 0 <if 0 swap else 0 then	| if n neg , 0 n  do 
     ?do dup i i@ aux@ i i! loop  
    else	| 
	 --aab 0 <if dup vbytes + Head# cells + aux@ vbytes - aux@ van move 
     else vbody aux@ van move then 
   then aux@ v?refs+ ref0del aux> ;

: ,L ( O0 O1 -- O2 )    | most basic catination of objects . Lisp like
  2 cellVecInit dup vbody dup
  4 pick refs+> swap  ! 2 pick refs+> swap cell+ ! nip nip ;

: cLsimple ( la ra -- r ) | except for symbols 
  i#i# + over Type@ VecInit >aux
  over van >r> aux@ vbody >r> swap move 
  dup van r> r> + swap move 2ref0del aux> ;

: cL local[ l0 l1 | n0 n1 adr -- adr ] 
| catinate Lists . keeps matching simple simple .
   l0 @  l1 @  or  if
    l0 @ l1 @ =if	| both same simple 
    l0 @ _n =if ." nil " cr  ,L ;then 	| nil is special .
    l0 @ TypeS =if l0 l1 ,L ;then
    l0 l1 cLsimple ;then 
   then
   
   l0 ?enc if  l0 i#  else  1  then to n0
   l1 ?enc if  l1 i#  else  1  then to n1
   
   n0 n1 + cellVecInit to adr
  l0 ?enc if l0 i# 0 ?do l0 i i@ refs+> adr i i! loop 
          else  l0 refs+> adr 0 i!  then
  l1 ?enc if l1 i# 0 ?do l1 i i@ refs+> adr n0 i + i! loop 
          else l1 refs+> adr n0 i! then
     | l0 l1 n0 n1 $.s 2drop 2drop | debugging
	 l0 ref0del l0 l1 <>if l1 ref0del then 
	  adr ;

: ,/ ( lst -- lst )		| discloses each item of lst . just returns simple 
 	dup Type@ if ;then  ['] cL across ;	

| Kludge fix of bug in Reva  ' search on some strings 
: search ( a1 n1 a2 n2 -- a3 n3 true | false ) 
   prior search 00; over 0 <if cr ." search error " $.s cr 3drop 0 then ; 

| \/ filterd to chars )| 256 _iota |( from C:\4thCoSy\src\reva.f
: lc ( c -- c' ) dup 65 90 between if $20 or then ;  
 
| \/  copied from  C:\4thCoSy\lib\string\misc unchanged  .
: strlwr ( a n -- a n ) 2dup bounds do i c@ lc i c! loop ;
: lower ( str -- str ) | convert string to lower case 
  dup vdup dup van strlwr 2drop swap ref0del ;   

| String Search . Returns indices of all occurances of S1 in S0 
| modeled on K _ss function 
| ' ssc is case sensitive . ' ss  is not . 
: ss ['] lower on2 : ssc ( S0 S1 -- IV )  2p 
   L@ i# 0if 2P 0 _iota ;then  | if L empty return empty 
   L@ vbody >aux L@ i# intVecInit >aux	| stk : ; aux : L.va res  
   L@ van -1 /string 	| L.va -1 , L.i# +1 
   L@ i# 1+ 0do  1 /string R@ van search | L.i+ n- true | false 
      if over auxx@ - aux@ i ii!	| S1 S1a S1n S0+ n- 
       else aux> i _take auxdrop leave
      then loop 2P> ; 

: _2takecalc ( i# n -- m )	>r> abs swap - 0 min r> sn * ; 
| computes parameter to convert a ` cut to a ` _take . 

: _cut\ _i : cut\ ( List Idxs -- CV )	| cuts string at Idxs , Arthur Whitney's def 
| Generally , partitions a list into sublists beginning at indices Idxs which must be a non-decreasing set of indices into List . e.g.: 
|   s" atari" i( 0 3 )i cut 
| ( s" ata"
|   s" ri" )
| 
| Note that number of items in the result equals the count of Idxs , and that to retain the leading portion of a list , Idxs must start with 0 . Any repeated indices will produce empty items in the result .
| A single item ix will essentially "drop" that many items from the beginning of List . As a special case , a single negative ix will drop that many items from the tail of List . e.g.:
|  i( 1 2 3 4 )i i( -1 )i  _
| (
|  ( 1 2 3 )
| )
  	2refs+> | single ix cases 
	dup i# dup 0if drop 2refs- ev ;then		| index empty -> empty
	1- 0if dup 0 i@ 0if refs- enc ;then	| index 0 return original , ref +ed 
     over i# over 0 i@ _2takecalc 2 pick swap _take >r 2refs- r> enc ;then
	 		| other single , take complement .
    dup i# dup cellVecInit >aux		| vec idxs	| real cut cases 
   1- 0 ?do --aaa i i@ swap i 1+ i@	| str Idxs a0 a1
   		3 pick -rot sublist refs+> aux@ i i! loop
   2dup -1 i@ over i# sublist refs+> aux@ -1 i!
  2refs- aux> ;    
 
: _cut _i : cut ( v i -- v ) | discloses if singlton index 
  dup i# >r cut\ r> 1 =if dsc then ; 
 
alias: _ cut 	| The K name .
 
: 0cut i0 swap cL cut ; | same as ' cut but includes portion before 1st cut   

: partition >_ : _partition ( v n -- v ) | cuts v into n parts .
| if v i# not multiple of n , last portion will contain the remainder .
   over i# over / _i swap  
   1- _take i0 swap ,I ['] + scanI _ ;

| APL reshape . eg : |  i( 1 0 -1 0 )i i( 3 3 )i take |
: take ( v idxs -- v ) | Note , tho , modulo indexing .
    ['] * scanI >aux> -1 i@ _take  aux> i-1 cut reverse >aux>  
    i# 0 ?do aux@ i i@ _partition loop auxdrop ;

| A useful variant from K.CoSy . See 20180506
| like singleton ' take but fleshes out with last ite
: _fill _i : fill ( l n -- l ) 2p L@ L@ rho i-1 +i R@ iota mini at 2P> ;
| algorithm from K but not generaized to neg arg .
| like  x # y  but repeats last element of y if x > # y
| { :[ 0< x ; y[ ( ! x ) & -1 + # y ] ; | _f[ - x ; | y ] ] }

0 [IF]
: nub ( v -- uniqueElements ) local[ v | r ]
  v v#@ VecInit to r  
  v i# 0 ?do v dup i i@ ['] 
  
: nub ( v -- uniqueElements )  
   1p 
[THEN]

: fmtI ( Iv -- Str )	| format integers . returns list of each number 
	| converted to a string .
   dup i# cellVecInit >aux>
   i# 0 ?do dup i i@ (.) str refs+> aux@ i i! loop
   ref0del aux> ;
 
: fmtI$ hex fmtI decimal ;
 
: fmtF ( Fv -- Str )	| format floats . returns list of each number 
	| converted to a string .
   dup i# cellVecInit >aux>
   i# 0 ?do dup i i@ sigdig @ (f.) str refs+> aux@ i i! loop
   ref0del aux> ;
 
: fmtnF >_ : _fmtnF ( f precison -- strs ) sigdig xchg >r fmtF r> sigdig ! ;

0 [IF]
: fmt ( v -- str )	| format numbers . returns list of each number 
	| converted to a string .
	dup @ dup TypeC and if drop ;then	| if already char , return .
	dup TypeI and if drop fmtI ;then
	dup TypeFl and if drop fmtF ;then
	ref0del drop z" nonce" throw ;
[THEN] 	| See ' lst for simpler ' fmt |

: filter ( la ra fn -- r )	| applies bool fn to la and ra returning true items
	2 pick refs+> >r each & r@ swap at\ r> refs- ;

: braket ( str strs -- str ) 2p> 0 _at swap cL R@ 1 _at cL 2P> ; 
| Prefixes and suffixes str with 2 item strs . Examples :  
|      s" 2 item"  s" <i>" s" </i>" ,L braket
|  s" <i>2 item</i>"
|     s" /4thCoSy/CoSy/Furniture.f "  s"  | " enc braket
|  s"  | /4thCoSy/CoSy/Furniture.f  | " 
|     i( 5 6 5 )i 4 _i braket
|  4 5 6 5 4 

: tokcut ( str tok -- CV )	| cuts string at occurances of string `tok but includes segment before first token 
  2p LR@ ssc i0 swap ,I L@ swap cut 2P> ;
 
: VM : toksplt ( str tok -- CV )	| like ' tokcut but deletes the tokens from the cut pieces 
   | cr ." toksplt " ( 2p> tokcut  i0  R@ rho   ) 
   2p LR@ swap cL >aux+> dup R@ ssc cut 	| appends 
   aux- R@ rho ['] cut eachleft  2P> ;
 
| Finessing bomb on 0 occurances of tok . See Mon.Mar,20170306 |
| : toksplt 2p> swap cL R@ prior toksplt 1 _cut 2P> ; 

|  name from APL " Vector to Matrix " 
: VMbl "bl toksplt ; 
 
: VMnl ( str -- list_of_strings_split_on_cr ) "nl toksplt ;
|   Vector to Matrix on "newlines" . 
 
: VMlf ( str -- list_of_strings_split_on_cr ) "lf toksplt ;

: ssr ( str  s0 s1 ,L -- str ) | replaces occurences in str of s0 with s1   
  2p L@ R@ 0 i@ toksplt dup i# 1 =if refs- L@ 2P> ;then  
  R@ 1 i@ ['] cL eachleft ,/ R@ 1 i@ rho -1*i cut 2P> ;

|  2p L@ R@ 0 i@ ss dup i# 0if L@ 2P> ;then 
|  R@ 1 i@ ['] cL eachleft ,/ R@ 1 i@ rho -1*i cut 2P> ;

| Quick ( to think ) and dirty . Could be highly optimized .

: 'd ( LA RA fn -- R )  
   >r 2p r> LR@ longer_ ev swap
   0 ?do L@ i _at R@ i _at l0@ execute cL loop 2P> ; 

: eachm ( RA fn -- R ) swap 1p ev >aux  | catinates 
   R@ i# 0do R@ i _at 2 SF@ execute aux> swap cL >aux loop
   1P drop aux> ;

: enc' ['] enc eachm ;  | enc each ( 'm bombs on floats ) 

: cLr ( p0 l1 -- )		| catinate Lists , replace . 
  | note , for use in appending to dic , encloses second arg so treated as
  | one item . even if already nested list .
  over @ swap enc cL swap rplc ;


: m>l ( obj -- lst ) dup+ m@ ?dup if refs+> else nil refs+> then ,L ;
| returns 2 item list with value and meta of obj
 
: l>m ( lst -- obj ) >r> i1 at\ r@ i0 at\ --bab m! r> ref0del ;
| takes 2 item list and sets meta on 0th to the second . 


: _nth ( CSob n -- CSadr )  	| extracts nth item from each item of CSob  
   _i 2refs+> ev  2 pick i# 0 ?do 2 pick i i@ 2 pick at\ cL loop >r 2refs- r> ;     		

: flip ( CSob -- CSob )    | Transpose list of 2 lists .
| returns list of each item of 1th list w corresponding item of 1st suject
| to the minimum length of the 2 lists . 
| 
   dup @ if ;then		| transpose of a simple obj is itself 
   dup i# 0;drop 		| same for empty
   refs+> dup ['] rho 'm ,/ ['] min _./ i_ cellVecInit >aux> 	| ob nbdy
    i# 0 ?do dup i _nth refs+> aux@ i i! loop 
    refs- aux> ; 

: symin_ ( symb sl -- flg ) swap ['] str~_ _f? _n <>I ;
| Like K's _in for symbols . Returns 1 if symb is in sym list
	
: symin ( symb sl -- flg ) symin_ _i ;
	
: lsymin ( symLst symLst -- boolLst ) ['] symin eachleft  ['] cL across ;
| Like K's _lin for symbols . Returns 1 each mem of LA in RA . 

: cconb ( strings str -- bool )	| returns bool where stings in LA contain RA 
   2refs+> 2dup ['] ssc eachleft { i# sn _i } eachM> ,/ --cab 2refs- ;  
 
: cconn ( strings str -- idxs )	| returns indexs of stings in LA containing RA 
   cconb & ; 
 
: ccon ( strings str -- strings )	| returns stings in LA containing RA
   2p L@ dup R@ cconn at\  2P> ; 
 
: ncconn cconb 0=i & ;
 
: conb  ( strings str -- bool ) 2p L@ ['] lower eachM> R@ lower cconb 2P> ; 
 
: conn ( strings str -- idxs ) | case insensitive  conn 
  conb & ; 
 
: nconn conb 0=i & ;
 
: con ( strings str -- strings )	| returns stings in LA containing RA
   2p L@ dup R@ conn at\  2P> ; 
 
: ncon 2p L@ dup R@ nconn at\  2P> ; 

cr cr  ." | /\ Fns /\ | \/ Dic \/ | Stk : "  $.s  cr cr 

." \\/ DICTIONARY  \\/ " $.s cr 
| \/ ============================================ \/
| 20110814 | have determined that really do need explicit type . Was just 3 vec

$006346964 value TypeDic		| " dic" 

| empty dictionary : 2 empty vecs . 

: () : ed ( -- emptyDic ) ev enc 2 _take ( TypeDic over Type! ) ;	

 ed  refs+> value R 	 | initialize empty Root dictionary

: d#_ ( dic -- #items_raw )  0 i@ i# ;
 
: d# ( dic -- #items ) d#_ _i ;

: dicapnd ( val dic name -- )	| adds item to dictionary
   refs+> dup name?_ 0if refs- ref0del ref0del z" invalid name " throw then
  swap >r> 0 ix swap cLr r> 1 ix swap cLr ; 
  | 2 ix nil cLr  ;

| : reasgn ( addr name vadr0 -- )       

| Type0 , TypeC , TypeI , TypeFl , TypeS , TypeV , TypeA , TypeFv |

." /\\ DICTIONARY  /\\ ======/\\  " $.s cr

| match obj str , I-logic .
: strmatch_ ( s0 s1 -- 0|1 )	
  2dup van rot  van str= -rot 2ref0del ;  : strmatch strmatch_ _i ;

| Match 2 objects .  Returns 1 iff LA identical to RA .
: match_ ( la ra -- bool ) 
  2refs+> ( ." match_ " $.s cr 2dup ,L lst )
  2dup =if 2refs- 1  ( ." same addr " cr ) ;then 	| refer to same object 
  Type@@ <>if 2refs- 0 ( ." ~= types " cr ) ;then 	| Types don't match 
  ['] i# on2> <>if 2refs- 0 ( ." ~= rho " cr ) ;then 	| lengths don't match
  dup Type@ if | simple 
   dup Type@ dup TypeS = swap TypeC = or if 2dup strmatch_ --cab 2refs- ;then
  ( $.s ) ( la ra )
   dup Type@ TypeI =if 2dup =i ['] and acrossI >_ --cab 2refs- ;then
   dup Type@ TypeFl =if 2dup =f ['] and acrossI >_ --cab 2refs- ;then
  then  ( ." nested , same count " cr $.s cr )
   dup i# 0do over i i@ over i i@ $.s 2dup ,L lst cr match_ 0if  0 leave then loop  
   dup if 1 then --cab 2refs- 
;
 
: match match_ _i ; 

| returns index of first occurance of sym in list or _n if not found .
: ?sym_ ( lst str  -- i | _n )	['] strmatch_ _f? ;   

: ?sym ['] strmatch f? ;

| returns index of first occurance of sym in dic names , else _n .
: (wheresym) ( dic sym -- i | _n )
   swap dsc swap ?sym_ ; 
 
: wheresym (wheresym) _i ;

| : symfind wheresym _n; dic 1 i@ swap ix ;

| delete items at i from v |  Currently i must be sorted and unique .   
: dvi ( v i -- v )	
  2p L@ dup i# R@ i# - swap @ VecInit >aux 0 temp rp
  L@ R@ over i# 0 ?do dup temp @ i@ i <>if over i i@ aux@ i temp @ - i! 
  					else temp ++ then loop 2drop temp rP aux> dup v?refs+ 2P> ;
	
| delete items at i from table of same length lists  , eg , a dictionary .      
: dti ( table i -- )  2p L@ dup 
	i# 0 ?do dup i ix dup @ R@ dvi swap rplc loop drop 2P ;

| delete item named sym from dictionary .
: dts ( dic sym -- ) 2p> wheresym L@ swap dti 2P ;

: dnames ( dic -- names ) 0 _at ; 

| \/ | look up symbol in dictionary , return address of corresponding val or _n 
: vx_ ( dic sym -- adr of value | _n )
    --aab (wheresym) dup _n =if nip ;then swap 1 i@ swap ix ; 

: sx_ ( dic sym -- adr of symbol | _n ) 
   --aab (wheresym) dup _n =if nip ;then swap 0 i@ swap ix ; 

: undefthrow  ( idx --  | throw ) dup _n =if drop z" undefined " throw then ; 

| fetch symbol associated with symbol in dictionary
: s@ ( dic sym -- sym ) sx_ undefthrow @ ;	

| fetch value associated with symbol in dictionary
: .v@ ( dic sym -- val ) vx_ undefthrow @ ;	
 
: v@ ( D idx -- val ) encatom ['] .v@ Y./ ; 	| eg: | R `( a b c )` v@
| if I were smarter , maybe I'd use | prior v@ | . need to play w first .

| store value associated with symbol in dictionary
: .v! : v! ( val dic sym -- )
	--bca ( dic sym val ) 2refs+> 2dup 2>aux --abcab vx_ 
	dup _n =if  drop --cab dicapnd 
	        else  rplc 2drop  then
	2aux> 2refs- ;
 
: v! ( v D idx -- ) | store value generalized to list addr | 20180506        
      encatom swap >aux 2p L@ aux> R@ -1 _cut v@ R@ i-1 take dsc .v! 2P ; 
 
: v!> ( val dic sym -- dic ) over >r v! r> ; 
	
| fetch value ( which must be string ) and evaluate 
: v* ( dic sym -- result )
 v@ van eval ;


: >< ( sym val -- dic )		| creates dic with sym and val .
	swap enc swap enc ,L ; 

: djoin ( dic dic -- dic )  { cL enc } 'd ;
| catinates each list of pair of lists , eg , dictionaries . see 20180218 .

: symrplc ( dic oldsym newsym -- )
  >r swap 0 i@ --bba  ?sym_   dup _n =if 2drop z" undefined " throw then
   ix r> swap rplc ;

: TaddCol ( mat proto -- mat ) | Adds a list of prototype to a table of equal
| length lists .
 2refs+> 2dup 2>r enc over 0 i@ i# _take enc cL 2r> 2refs- ;  

: vdel ( dic sym  -- ) | deletes entry from dictionary
    2p> (wheresym) dup _n =if drop 2P ;then
    _i refs+> 
	dup L@ 0 ix dup @ rot dvi swap rplc 
	dup L@ 1 ix dup @ rot dvi swap rplc 
	refs- 2P ;
 
| : vdel 2p  { prior vdel } eachM ;  

: dsel ( dic syms -- dic ) | returns dic of items named in list syms .
   2p R@ R@ { L@ swap v@ } eachM> ,L 2P> ; 

 macro
: `` p: sym vx_ ;	| returns address of dic obj . 
: `@ ( dic <sym> -- val ) p: sym v@ ;
: `! ( val dic <sym> -- ) p: sym v! ;
: `. p: `@ lst ;

: --> ( val dic <name> -- dictionary entry )  p: sym v! ;
 forth

: csasgn  ( adr <name> -- encVadr ) | CoSy assign
  p: sym swap ,L ;

: (cs@) ( dic n -- csobj )
  >r dup 0 i@ r@ i@ swap 1 i@ r> i@  ,L ; 

| : z ( ... Fadr0 Fadr1 -- ... )          | compoZe , takes 2 fn tags
|   >r execute r> execute ;              | not clear worth anything

."  /\\ dic /\\  ---  E o Script | " cr  

needs Furniture.f	| Furniture : fns to flesh out the living area .

cr ." \\/ RESTORE \\/  " $.s cr 	| =============== |

 " COSYSTARTFILE" getenv str >value COSYSTARTFILE 
 COSYSTARTFILE dup s" \" ss -1 _at i1 +i take >value CoSyDir
 
: curdrive s" cd " shell> 2 _take ; 
: fullCoSyFile curdrive COSYSTARTFILE cL ; 
: CoSyFile  COSYSTARTFILE s" \" toksplt -1 _at ; 

needs SaveRestore.f

| Reva takes first command line parameter as script to load , eg , this CoSy.f .
| By default this loads the  *.csy  dictionary named in COSYSTARTFILE
| environmental variable . 

| Reva takes first command line parameter as script to load , eg , this CoSy.f .
| By default this loads the  *.csy  dictionary named in COSYSTARTFILE
| environmental variable . If a second argument is present , it is
| loaded instead . 
| CoSyFile dsc o restorefile ' R rplc
 

 COSYSTARTFILE s" .csy" cL ." COSYSTARTFILE " o cr restorefile ' R rplc    

| restore | R R --> _R | neat line , but then R `. _R  is recursive catastrophy  

 cr ." /\\ RESTORE /\\" cr

: Rnames R dnames ; 

| ' dup doesn't work in computations w refd lists . 
| Need to ' rep to get 2 0 counted copies .
 
: rep_ dup vsize ( a s ) dup allocate >r> swap ( a r s ) move r@ refs0 r> ; 
| rep on simples .
 
: rep ( ob -- newob ) | replicate object . totally new
	 dup Type@ if rep_ ;then
	    duplst ;
 
: .. dup rep ; 	| equivalent of ' dup for CoSy objs .


: >at!> rep dup at! ; 

: fmtS : sym>str> ( sym -- str ) .. dup sym>str swap ref0del ; 
: str>sym> ( str -- sym ) .. dup str>sym swap ref0del ; 

| : fmt dup Type@ TypeS =if sym>str> ;then prior fmt ; | see ' lst  
| kludge to deal w symbols . See 20180130

| \/ | Result returning version on shallow lists 
: sym>str>' rep { dup sym>str } 'm ; 
: str>sym>' rep { dup str>sym } 'm ; 	| Tue.Aug,20160830
 
: symcon ( list_of_sym str -- strs ) swap sym>str>' swap con str>sym>' ; 
 
| Makes me reconsider Morten Kromberg's question at 
| http://cosy.com/CoSy/MinnowBrook2011.html 
| " What is a symbol other than a string ? "
| /\ | 


| ~\/ | DictionaryTable > < .csv text | ~\/~\/~\/~\/~\/~\/~\/~\/~\/~\/~ |
 
| I've used the term , abbreviated ' DT , in K.CoSy with a rather substantial
| vocabulary . It is the fundamental form of a Kdb columnar data base . 
| A DT is a Dictionary whose first item is a list of column labels and second is | a corresponding set of correlated lists of values . This vocabulary converts
| back and forth between CoSy DTs and standard .CSV strings , the most 
| universal format for bank ledger downloads . See 20171212 .
 
: csv>lst ( csv d0,d1 -- lst ) 2p> dsc VM R@ 1 _at ['] VM 'L 2P> ;
: lst>DT ( lst -- DT ) 1p> dsc R@ 1 _cut flip ,L 1P> ; 
: csv>DT ( csv d0,d1 -- DT ) csv>lst lst>DT ;
 
| \/ | Example | \/ | 
 
| s" C:/CoSy/acnts/y17/CHK.CSV" F> >T0> -2 _take c>i 	|>| 13 10
|  read in and check if line delimiter is "lf or "cr "lf . generally trailing .
 
| T0 "nl "ht ,L csv>DT >T1 	
|  | Note the combining of the line and item delimiters by ' ,L 
 
| And the inverse 
: DT>lst 1p> dsc enc R@ 1 _at flip cL 1P> ; 
: lst>csv ( lst d0,d1 -- csv ) 2p> dsc ['] MV 'L R@ 1 _at MV 2P> ; 
: DT>csv ( DT d1,d0 -- csv ) 2p> --aba dnames sym>str>' swap MV 2P> ;
 
|  | Note that the delimiters have to be reversed . 
| T1 "nl "ht ,L reverse DT>csv 
 
| ~/\~| DictionaryTable > < .csv text | \~/\~/\~/\~/\~/\~/\~/\~/\~/\~/\ |

| ||


 R refs+> value _d
 
: Dnames _d dnames ; 

: Dwheresym ( str -- i | _n ) _d swap (wheresym) ;

: Dvx_ ( sym -- adr of value | _n )	| takes symbol 
	| look up symbol in dictionary and return address of corresponding val or _n 
	_d swap vx_ ;
 

: Dv@ ( sym -- val | error ) _d swap encatom ['] v@ Y./ ;  

 
: Dv! ( val sym -- )	| Root variable store 
   _d swap v! ;

: Dvdel _d swap vdel ;

| append catinate ( ' cL ) object to list word in Dictionary . 20171114.
: v_cL ( val D s -- ) vx_ dup @ --bca cL swap rplc ;  
: Dv_cL ( val nm -- ) _d v_cL ;

| Utility treed variable 
: >R0> dup : >R0 R " R0" (sym) v! ;
 
: R0 R " R0" (sym) v@ ;

: >R1> dup : >R1 R " R1" (sym) v! ;
 
: R1 R " R1" (sym) v@ ;

: >T0> dup : >T0  R " T0" (sym) v! ;
: T0 R " T0" (sym) v@ ;

: >T1> dup : >T1  R " T1" (sym) v! ;
: T1 R " T1" (sym) v@ ;

| cr ." start RecurInterp "  $.s cr
| needs RecurInterp.f
 
needs Derived.f

cr ." here "  $.s cr

| needs Head#change.f

| needs math/big

 ` script0 Dv@ ^eval

needs Tui.f

ev >R0 	| 20180527

cr 
cr ." CoSy.f "  $.s cr
cr
." ( ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ) "
cr
cr
0 [IF]
."  The CoSy \"TextualUserInterface\" is now loaded . Enter \"go\" to start . 
  Note that the CoSy \"APL\" vocabulary is available here
  in the regular console mode ."
cr cr
."  In this mode , the prompt has been redefined to output the stack
 in hex after every execution . "
 cr cr
 | ." To start the TUI , just execute \"go\" "
| cr cr
 [ELSE]
." In case of crash , execute  'restart' at command prompt ." cr
." Execute 'restore' to replace CoSy.csy with backup CoSy.bk " cr 
  go
 [THEN]
| ################################################### |
