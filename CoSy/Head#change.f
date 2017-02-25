| Storing list w changed  Head#  .
| Author: Bob Armstrong / www.CoSy.com
| Reva's license terms also apply to this file.
| Sat.Aug,20110820 

| add cell for meta attributes pointer to head of object 

." | Head#change > | " cr

: convert ( obj -- str ) 
  dup vsize str >t0> 12 _take 4 byteVecInit cL >t1>
  t0 12 _iv _ dsc cL ;


 defer (convertlst)
 
: convertlst ( lst -- clst cells )    | convert allocated list to linear form
| Items are only stored once with pointers to previously stored instances 
| 
| NB : because the buffer is not a "CoSy" object , it is not reference counted
|  and must be freed after use . 
   2 M* allocBuf 	10 K* IlstInit
   (convertlst)
   buf bpos @ resize to buf  buf bpos @ Ilst @ refs- ;
|
 : ((convertlst)) ( lst -- ) 
   >aux> Ilst? | search saved addresses , return index or  _n
   	dup _n =if
		( NEW ) drop aux@ Ilst!
 		  aux@ Type@ if
		  
		  ( SIMPLE ) 	."  simple " cr | store in buffer 
		   aux> convert >aux 
		   bufcur aux@ van --bac  | $.s cr
		    >r> move r> bpos +! aux> refs- ;then
		 
		   ( LIST ) 	."  list " cr
		   aux@ 
		    bufcur Head# cells >r>	  	| $.s cr | add extra head cell
		    move r> bufinc
		    0 bufcur ! cell bufinc		   	| $.s cr   | store head
		   aux@ i# 0 ?do aux@ i ic@ ((convertlst)) loop auxdrop ;then
		   			| /\ iterate thru items  	  
	    ( ALREADY STORED ) negate bufcur ! cell bufinc auxdrop ;
 
' ((convertlst)) is (convertlst)


|||

  s" asdf" enc >t0> convertlst dump
  
  R convertlst --aab str >t0 free 
  s" /reva/cosy/Head4.c4" Foverwrite 



| /\ /\ |
