| Proto 4th.CoSy Interface 
|
| Author: Bob Armstrong building upon resources created by 
|  Danny Reinhold / Reinhold Software Services
| upon the IUP GUI toolkit:
| Copyright © 1994-2005 Tecgraf / PUC-Rio and PETROBRAS S/A.
|
| Reva's license terms also apply to this file

cr ." | Job.f  begin | "  

~ needs ui/gui exit~ 

with~ ~iup with~ ~ui

| .~ cr cr


_n dup value dlgH  value txtH 

: newwdo ( -- dialogHandle_MultiLineHandle )
 z" multilineAction" IupMultiLine 
 dup z" EXPAND" z" YES" IupSetAttribute drop
 dup IupDialog swap 2_i cL ;



: JobHndl s" Tui" v@ s" hndl" v@ ;
: JobHndld JobHndl 0 i@ ;  : JobHndlt JobHndl 1 i@ ;

: dhndl_ ( tui -- dialogHndl_ ) s" hndl" v@ 0 i@ ;
: thndl_ ( tui -- textHndl_ ) s" hndl" v@ 1 i@ ;
 
: showXY ( dlgH X Y -- ) IupShowXY drop ; 

: getX ( dlgH -- int ) z" X" IupGetAttribute zcount >single drop ;
: getY ( dlgH -- int ) z" Y" IupGetAttribute zcount >single drop ;
: getpos ( dlgH -- X Y ) dup getX swap getY ; | get UL corner pos of window .

: setsize ( s" XxY" dlgH -- ) swap z" SIZE" swap van zt IupSetAttribute drop ;
: getsize ( dlgH -- s" XxY" ) z" SIZE" IupGetAttribute zcount _str ;


: setAttr ( H lbl str -- ) dsc zt swap dsc zt swap IupSetAttribute drop ;  

: setfont ( font thndl -- ) z" FONT" --bca van zt IupSetAttribute _i ;  
: getfont ( thndl -- s" " ) z" FONT" IupGetAttribute zcount _str ;

: settxt ( str txtH -- ) z" VALUE" --bca van zt IupStoreAttribute _i ; 

: gettxt ( txtH -- str ) z" VALUE" IupGetAttribute zcount _str ; 

: settit ( str dlgH -- ) swap z" TITLE" swap van zt IupStoreAttribute drop ; 
: gettit ( dlgH -- str ) z" TITLE" IupGetAttribute zcount _str ; 

: settab ( str dlgH -- ) swap z" TABSIZE" swap dsc zt IupStoreAttribute drop ; 
: gettab ( dlgH -- str ) z" TABSIZE" IupGetAttribute zcount _str ; 

: savetxt ( -- ) | uses globals dlgH and txtH  
 dup 1 c+ @ gettxt R rot @ gettit v! ;
| saves text of text dialog based on title .

: svtxt ." svtxt | " $.> txtH gettxt R dlgH gettit v! ." | " $.> cr ;

: setWdo ( Job -- ) 1p  newwdo >a> R@ s" Tui" v@ >a> s" hndl" v! 
| aux@ is Tui  auxx@ is hndl 
| auxx@ lst aux@ lst  cr
  a@ s" SIZE" v@ auxx@ 0 i@ setsize
  a> s" FONT" v@ a@ 1 i@ setfont
  R@ s" text" v@ a> 1 i@ settxt 
 1P ;

: showWdo dup JobHndld swap s" Tui" v@ s" posXY" v@ lst>stk_  IupShowXY _i ;

|  auxx@ 1 i@ a@ s" posXY" v@ lst>stk_ IupShowXY _i 1P> ; 

: rShow "lf MV s" .r text" blVM Dv! s" .r" Dv@ dup setWdo showWdo ;
: rWdoUpdate  "lf MV s" .r" Dv@ JobHndlt settxt ;
| : rGet ` .r Dv@ JobHndlt gettxt `( .r text )` Dv! 	| retrieve changed text from window



0 [IF] 
: showWdo ( Job -- ) 1p  newwdo >a> R@ s" Tui" v@ >a> s" hndl" v! 
| aux@ is Tui  auxx@ is hndl 
| auxx@ lst aux@ lst  cr
 auxx@ 0 i@ dup aux@ s" SIZE" v@ $.s cr setsize

 ( dhndl ) aux@ s" posXY" v@ .. 0 i@ swap 1 i@ $.s cr IupShowXY drop 
 auxdrop a-  1P 
 ; 

 [THEN]

: closeWdo ( Job -- ) s" Tui hndl" blVM v@ >_ IupDestroy drop ; 


: closedlg dlgH IupDestroy drop  _n dup addr dlgH 2! ;


| \/ | really nothing below here  | \/ | =========== |

." | Job.f end | " cr 
