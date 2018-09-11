| Proto 4th.CoSy Interface 
|
| Author: Bob Armstrong building upon resources created by 
|  Danny Reinhold / Reinhold Software Services
| upon the IUP GUI toolkit:
| Copyright © 1994-2005 Tecgraf / PUC-Rio and PETROBRAS S/A.
|
| Reva's license terms also apply to this file

cr ." | Job.f  begin | " cr 

~ needs ui/gui exit~ 

with~ ~iup with~ ~ui

| .~ cr cr


_n dup value dlgH  value txtH 

: newwdo ( -- dialogHandle_MultiLineHandle )
 z" multilineAction" IupMultiLine 
 dup z" EXPAND" z" YES" IupSetAttribute drop
 dup IupDialog swap 2_i cL ;

: dhndl_ ( tui -- dialogHndl_ ) s" hndl" v@ 0 i@ ;
: thndl_ ( tui -- textHndl_ ) s" hndl" v@ 1 i@ ;
 
: showXY ( dlgH X Y -- ) IupShowXY drop ; 

: getX ( dlgH -- int ) z" X" IupGetAttribute zcount >single drop ;
: getY ( dlgH -- int ) z" Y" IupGetAttribute zcount >single drop ;
: getpos ( dlgH -- X Y ) dup getX swap getY ; | get UL corner pos of window .

: setsize ( dlgH s" XxY" -- ) z" SIZE" swap van zt IupSetAttribute drop ;

: getsize ( dlgH -- z" XxY" ) z" SIZE" IupGetAttribute zcount str ;


: setAttr ( H lbl str -- ) dsc zt swap dsc zt swap IupSetAttribute drop ;  

: setfont ( font thndl -- ) z" FONT" --bca van zt IupSetAttribute _i ;  

: settxt ( str txtH -- ) z" VALUE" --bca van zt IupStoreAttribute _i ; 

: gettxt ( txtH -- str ) z" VALUE" IupGetAttribute zcount str ; 

: settit ( str dlgH -- ) swap z" TITLE" swap van zt IupStoreAttribute drop ; 
: gettit ( dlgH -- str ) z" TITLE" IupGetAttribute zcount str ; 

: settab ( str dlgH -- ) swap z" TABSIZE" swap dsc zt IupStoreAttribute drop ; 
: gettab ( dlgH -- str ) z" TABSIZE" IupGetAttribute zcount str ; 

: savetxt ( -- ) | uses globals dlgH and txtH  
 dup 1 c+ @ gettxt R rot @ gettit v! ;
| saves text of text dialog based on title .

: svtxt ." svtxt | " $.> txtH gettxt R dlgH gettit v! ." | " $.> cr ;



: showWdo ( Job -- ) 1p  newwdo >a> R@ s" Tui" v@ >a> s" hndl" v! 
| aux@ is Tui  auxx@ is hndl 
| auxx@ lst aux@ lst  cr
 auxx@ 0 i@ dup aux@ s" SIZE" v@ $.s cr setsize

 ( dhndl ) aux@ s" posXY" v@ .. 0 i@ swap 1 i@ $.s cr IupShowXY drop 
 auxdrop a-  1P 
 ; 

: closeWdo ( Job -- ) s" Tui hndl" blVM v@ >_ IupDestroy drop ; 


: closedlg dlgH IupDestroy drop  _n dup addr dlgH 2! ;


| \/ | really nothing below here  | \/ | =========== |

." | Job.f end | " cr 
