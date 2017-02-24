| "aux" stack words | enhanced from Reva |
|
| Author: Bob Armstrong / www.CoSy.com
| Reva's license terms also apply to this file.

cr ." | CSauxstack > | "
context: ~CSauxstack ~CSauxstack

| \/ | same as | C:\4thCoSy\lib\util\auxstack
1024 stack: (aux)
 
: >aux (aux) push ;
: >aux> dup >aux ;
: aux@ (aux) peek ;
: aux> (aux) pop ;
 
: aux# ( -- int ) (aux) dup @ swap - cell / ;
| /\ | same as | C:\4thCoSy\lib\util\auxstack

: >auxx aux> swap >aux >aux ;	| like ' tuck for aux stack
: >auxx> dup >auxx ;
: auxx@ (aux) @ cell- @ ;		| like ' over for aux stack .
: auxx> aux> aux> swap >aux ;	| like ' nip  for aux stack
 
: 2>aux >aux >aux ;		 : 2aux> aux> aux> ;  
 
: auxdrop aux> drop ;
 
: s>x ( n -- n items dropped from stack ) dup >r 0do >aux loop r> >aux ;
|  move n items from stk > aux & store n at new aux stk 0 point 
 |  sp (aux) @ rot dup >r move 		| to optimize 
 
: x>s ( -- n items restored from aux stack ) 
   aux> 0do aux> loop ;


| : auxfence+ ( n -- ) (aux) dup @ dup @ 3 pick	| add n cells to the stack frame 
|   cells rot + swap 3 pick +  over ! swap ! drop ;
| Note these locals are not protected against overwriting
|  by called fns . To protect them , use  auxfence+ to add more
| cells to the stack frame . Note then , of course your indexing
| of parameters will change by the number of cells added .


| ----------------------------------------------------------------- |

| |\/| StackFrames |\/| ================================== \/ |  
." |\\/| StackFrames |\\/| "  
| The above does not answer the need for recursive stack frames .
| This is implementing the notion in George B. Lyons : Stack Frames and Local Variables :  http://www.forth.com/archive/jfar/vol3/no1/article3.pdf
 
 s0 cell- dup constant s1 dup dup !  variable, SFptr 	 	
 | relies for stopping on the 0th stack cell being set to itself 
	| initialize StackFrame pointer 
| SFptr @ dup @ !
  
: reset prior reset s1 SFptr ! ;
 
: SF+ | puts previous esi on the stack and saves current 
	  esi@ cell- SFptr xchg ;
 
: SFx cells SFptr @ + ; 	| ( n -- n ofset by current pointer ) 
 
: SF@ SFx @ ;  	: SF! SFx ! ;  | Fetch and store relative to current pointer
 
: SF- | ( ... n -- drop n ) restores previous stack pointer but just drop n items beyond current pointer .
	>aux SFptr @ dup @ SFptr ! cell+ esi! aux> ndrop ; 

| of ?able worth
| : SF_ ( res -- res ) >r 0 SF@ dup @ SFptr !   esi! r> ;
| : SF- | restores previous stack pointer .
|   SFptr @ @ dup s0 =if drop ( ." s0 " cr ) s0 dup SFptr ! cell- esi! ;then 
|     dup SFptr ! esi! ; 

| : SFn ( -- n ) SFptr @ dup @ swap - cells/ - ;  | number of parameters in frame
	| undefined for empty stack .

: RA  1 SFx ;	: LA  2 SFx ;	| Shorthand for dyadic fns .
: R@  1 SF@ ;	: L@  2 SF@ ;
: R!  1 SF! ;	: L!  2 SF! ;
 
: LR@ 2 SF@ 1 SF@ ;
 
: l0 -1 SFx ; 	: l0@ -1 SF@ ; 	: l0! -1 SF! ; 
: l1 -2 SFx ; 	: l1@ -2 SF@ ; 	: l1! -2 SF! ; 


." |/\\| StackFrames |/\\| "  

exit~ with~ ~CSauxstack

." | < CSauxstack | "

