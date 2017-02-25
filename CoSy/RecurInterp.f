cr ." | Recursive Interpreter begin | "

| \/ INTERPRETER \/ \/ \/ \/

| \/ PARSER IN FORTH | reentrant \/ |
needs string/trim

variable _in variable _inn variable _more
128 stack: strstk 

notail
: str{ ( a n -- ) _inn strstk stkp  _in strstk stkp _more @ strstk push ; 
|  switch input parsing to arbitrary string . 

: }str cr strstk pop _more ! _in strstk stkP _inn strstk stkP ;
forth

| : _parsews _in 2@ splitws if _in 2! ;then     ;

| /\ PARSER IN FORTH | reentrant /\ |


| \/ input number conversion \/ |
variable ntype	( 0 -> ints , 1 -> floats )  variable nstkI | index   
100 intVecInit refs+> value istk  0 	100 floatVecInit refs+> value fstk   

: fl>stk ( float -- ) | append float to param stk . convert stk if int .
   ntype @ 0if  ntype on  nstkI @ 0 ?do istk i i@ s>f fstk i i! loop then
   fstk nstkI @>+! i! ;
: i>stk ( int -- ) | append int to param stk , convert if ntype 1  
  ntype @ if s>f fl>stk ;then istk nstkI @>+! i! ;  
| /\ input number conversion /\ |

| variable nArg

128 stack: CSstk

: nstk> ( -- a )	| moves nstk to allocated vec . 
   ntype @ if fstk else istk then nstkI @ _take nstkI off ; 

: n>CStk nstkI @ if nstk> CSstk push then ;   

: newobj ( a n -- dicIdx ) (sym) nil swap R dicapnd  R 0 i@ i# 1- ;

: x( ( -- lst ) | 
   _in 2@ 2dup " )x" search drop nip - type> $.s cr str >r 
   _in 2@ r@ i# 3 + /string _in 2!
   r> "; toksplt CSstk push ; 


128 stack: fnstk  variable self 
: >self> ( sym -- sym ) refs+> dup self fnstk stkp ; 
: self^ self dup @ refs- fnstk stkP ;

0 [IF] 
s"  here >aux :: " constant fe0	
s"  ; execute aux> (here) ! " constant fe1

: feval ( LA? RA? Cfn -- obj? ) >r>  
   fe0 swap cL fe1 cL >r> van type> cr 
   eval r> free r> ref0del ;

: feval ( LA? RA? Cfn -- obj? )
   dup self rp van eval cr ." fnshd " self @ ref0del self rP ;
[THEN]  

: feval ( LA? RA? Cfn -- obj? )
   dsc eval ;
   
: `x p: `@ feval ;

: _xn ( v_expr i ) over >r i@ feval r> refs- ;
 	| executes ith item of vec of expressions 


: RAx | evaluate right hand side - remainder of line - of a CSfn .
   ( -- false if eol | val true )  
   ;
	
defer CSex

: (xeq) ( sym -- ? )
   1p L@
   cr ."  CoSy | " vx dup $.> _n <>if CSex 1P cr  ;; else drop then
   L@ van cr $.s type> ."  | "
   cr ."  4th | "  ~sys.find-dict dup if n>CStk exec 1P cr ;; else drop then  
   cr ."  num | " >single if i>stk 1P ;; then
   cr ."  float | "  >float  if fl>stk 1P ;; then 
   cr ."  newobj | " newobj 1P ;


| variable curwrd

0 [IF]
: CSinterpret ( a n -- ) 0drop;
  str{ repeat cr ." CSi " _in 2@ splitws dup _more ! if _in 2! then 
        $.s type> ."  | "
        dup if (sym) >self> (xeq) ( self^ ) else 2drop then ." dun " $.s ( key drop ) _more @ while
       }str ;
  
|  $.s cr ' (xeq) >defer interp $.s eval  undo interp ;

make CSex ( dicvaradr -- ? ) cr ."   CSex " $.s cr  n>CStk 
    @ dup @ 
	dup noun? if $. ." noun " drop CSstk push ;then
    dup TypeFv =if $. ." Forth " $.s ." x| " feval ."  |x " $.s ;then
	dup TypeV =if $. ." CS " van CSinterpret ;
[THEN]

|  `@ - dup feval cr cr $.s

0 [IF]
str{ src @ $. >in @ $. cr
  repeat
  parsews type> space (sym) dup curwrd ! 
  cr ."  xeq " (xeq) ."  here "
  >in @ src @ $2.> < .> while 
 ."  exit "  }str ;

: setInp 

: CoSyeval ( a   input parsews noun? push 
 ;
 
 
\ Intrinsic types ; need no further structure
| s" nil" drop value nil
s" pars"

s"  " str c drop value pars
s-> INP
v0 refs+> value Parsed

\ : CSparse  ( str -- )
\  INP

\ INTERPRETER \ /\ /\ /\ /\ \


((
 s"  |) " drop value |)
 s"  (>) " drop value (>)
 s"  (| " drop value (|

))

[THEN]

." | Recursive Interpreter end | "
