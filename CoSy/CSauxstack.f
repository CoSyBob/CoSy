| "aux" and stack pointer words words | enhanced from Reva |
| See also 
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

64 stack: (lpstk)
 
: >lpstk (lpstk) push ;
: >lpstk> dup >lpstk ;
: lpstk@ (lpstk) peek ;
: lpstk> (lpstk) pop ;
 
: lpstk# ( -- int ) (lpstk) dup @ swap - cell / ;

: >lpstkx lpstk> swap >lpstk >lpstk ;	| like ' tuck for lpstk stack
: >lpstkx> dup >lpstkx ;
: lpstkx@ (lpstk) @ cell- @ ;		| like ' over for lpstk stack .
: lpstkx> lpstk> lpstk> swap >lpstk ;	| like ' nip  for lpstk stack
 
: 2>lpstk >lpstk >lpstk ;		 : 2lpstk> lpstk> lpstk> ;  
 
: lpstkdrop lpstk> drop ;

| \/ | Need aux stack  | \/ |

: onN ( a b c ... N f -- f on each a b c ... ) | see 20180119 
	>aux 0 ?do i pick aux@ xeq i put loop auxdrop ;

| /\ | ------------------------------------------------------------ |

| |->| StackFrames moved to ParameterPushing.f |<-| 

exit~ with~ ~CSauxstack

." | < CSauxstack | "