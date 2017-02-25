| Essential recursive Save and Restore list fns .
| Begun by the pool @ Dyalog & APL2000 Naples APL conference 200411
| when Ray Cannon had a spare room and everyone else was at sessions . 
| Author: Bob Armstrong / www.CoSy.com
| Reva's license terms also apply to this file.
| Sat.May,20070526 

| 20130815.0122 | Realized needed to make m>l and l>m  and can reliably 
| implement conversion on Meta-less 2 item lists 

| Saves just a single copy of each unique object 

cr ." | SaveRestoreM begin | " 

| \/ SAVE LIST  \/ ========================================== \/
0 [IF]

| Index list |
 variable Ilst variable Ilst# 
  ." Here Ilst "
  | increment the pointer and store the address 
 : Ilst! ( a -- ) Ilst @ Ilst# @>+! ( lengthen Ilst first ) 
   Ilst# @ Ilst @ cell+ !  ic! ;
 
 : Ilst? ( obj -- idx_or_nil ) Ilst @ swap ['] = _f? ; 
 
: IlstInit ( size -- ) intVecInit refs+> Ilst !
	1 Ilst cell+ ! ( length to 1 )  Ilst# off ;  
| Index list end |

[THEN] 
 
 defer (storelstM)
 
: storelstM ( lst -- clst cells )    | convert allocated list to linear form
| NB : because the buffer is not a "CoSy" object , it is not reference counted
|  and must be freed after use . 
   2 M* allocBuf 	10 K* IlstInit
   ." storelstM " cr
   (storelstM)
   buf bpos @ resize to buf  buf bpos @ Ilst @ refs- ;
 
: ((storelstM)) ( lst -- ) | aux  is the list address 
   >aux> Ilst? | search saved addresses , return index or  _n
    ." ((storelstM)) " $.s cr 
   	dup _n =if
		( NEW ) drop aux@ Ilst! 
 		 ." (NEW) " 
		aux@ @ if		| 0 means list 
		
         ( SIMPLE ) | store in buffer
           ." ( simple ) "  
		   aux@ bufcur aux@ vsize >r> move r> bpos +!
		   aux> m@ ?dup ."  meta ? " $.s  cr 
		    if ((storelstM)) then | store meta if defined 
		   ;then 
		   
		 ( LIST )  ." ( list ) "   aux@ bufcur Head# cells >r>
		    move r> bufinc | store head
		    aux@ mx @ ?dup ." meta " $.s if ((storelstM))	then
		   aux@ i# 0 ?do aux@ i ic@ ((storelstM)) loop | /\ iterate thru items
		   auxdrop ;then 

	| If already stored , just store the negated address of the existing copy 			
	    ( ALREADY STORED ) negate bufcur ! cell bufinc auxdrop ;
 
' ((storelstM)) is  (storelstM)

| ======== |
  ."  HERE "
1 [IF]
 ." | Restore | " 
| ======== |

| convert linear form back to allocated
defer (rstrlstM)
 
: restorelstM ( addr -- lst )		| address of dic linear representation        
   to buf  bpos off		| uses allocbuf buffer vars . 
   10 K* IlstInit
    ." restorelstM " cr
   (rstrlst) Ilst @ refs-  | memory tree structure
    ;
 
: ((rstrlstM)) ( -- lst ) 
     bufcur  dup @ dup
     ." ((rstrlstM)) " $.s cr 
	  0 <if ( ALREADY RESTORED ) nip negate Ilst @ swap ic@ 	| neg value means already created with address the abs value 
	  refs+> cell bpos +! ;then 	| just bump the ref count , inc the buffer position 
	 
	  ( NEW )
       0if ( LIST ) i# dup cellVecInit	| bufadr i# new		
	   1 over refs!  dup Ilst! Head# cells bpos +! 
       swap 0 ?do ((rstrlst)) over i ic! loop
       aux> mx >r> @ if r> ((rstrlstM))
       ;then 
	  
      ( SIMPLE ) dup vsize dup bufinc 
       ." ( simple ) "  $.s 
	   aligned dup allocate >r> Ilst!	| is ` aligned necessary ?
	    $.s cr
	   r@ swap move 1 r@ refs!		| r holds addr of obj
	   r@ mx ?dup if ((rstrlstM)) r> over m! 1 over mx refs!    
	   ;
 
' ((rstrlstM)) is (rstrlstM)
 
: restorelistM ( str -- dic ) dup vbody restorelst swap ref0del ;

| --------- |

: (restorefile) ( a n -- lst )
  slurp 0if ." should throw" z" (restorefile) : file empty or non-existant " throw then 
  dup restorelst swap free ;
 
: restorefile ( str -- lst )  ['] (restorefile) onvan ;  | str is file name .

| ======== |

: (savelst) ( lst c-adr n -- )    | write list to file c-adr n
   foc dup -1 =if drop z" (savelst) : file tie failure" throw then  >r
   storelst --aab r@ write ioerr @ swap nakedfree
    if z" file write error " throw then 
   r> close ;
 
: savelst ( lst <fname> -- )
 parsews (savelst) ;
 
: savelist ( lst str -- ) | Write list to file 
  2p>  van (savelst) 2P ;


| defer CoSyDir  make CoSyDir " \\reva\\CoSy\\" ;

  instdir " CoSy" add-path scratch place
  scratch count add-separator str refs+> value CoSyDir

defer CoSyFile  make CoSyFile " CoSy" ;

| : CoSyDicFile CoSyDir CoSyFile strcatf ; 

: savedic ( -- ) | save dictionary	|  
  " del " CoSyDir van strcatf CoSyFile strcatf " .bk" strcatf shell 
  " ren " CoSyDir van strcatf CoSyFile strcatf " .csy CoSy.bk" strcatf shell 
  R CoSyDir van CoSyFile strcatf " .csy" strcatf (savelst) ;

| : savedic ( -- ) | save dictionary	|  
|  " del " CoSyDir van strcatf CoSyFile strcatf " .bk2" strcatf shell 
|  " ren " CoSyDir van strcatf CoSyFile strcatf " .bk CoSy.bk2" strcatf shell 
|  " ren " CoSyDir van strcatf CoSyFile strcatf " .csy CoSy.bk" strcatf shell 
|  R CoSyDir van CoSyFile strcatf " .csy" strcatf (savelst) ;

| ======== |
 |  CoSyDir 

: restore CoSyDir van CoSyFile strcatf " .csy" strcatf
   (restorefile) ['] R rplc ;

: duplstM ( lst -- nwlst )
  storelstM drop dup restorelstM swap free ;

| /\ SAVE LIST  /\ ========================================== /\
[THEN]
." | SaveRestore end | "  cr

