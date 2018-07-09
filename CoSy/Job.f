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

: showXY ( dlgH X Y -- ) IupShowXY drop ; 

: getX ( dlgH -- int ) z" X" IupGetAttribute zcount >single drop ;
: getY ( dlgH -- int ) z" Y" IupGetAttribute zcount >single drop ;
: getpos ( dlgH -- X Y ) dup getX swap getY ; | get UL corner pos of window .

: setsize ( dlgH z" XxY" -- ) z" SIZE" swap IupSetAttribute drop ;
: getsize ( dlgH -- z" XxY" ) z" SIZE" IupGetAttribute ;


: setAttr ( H lbl str -- ) dsc zt swap dsc zt swap IupSetAttribute drop ;  

: settxt ( str txtH -- ) swap z" VALUE" swap van zt IupStoreAttribute drop ; 
: gettxt ( txtH -- str ) z" VALUE" IupGetAttribute zcount str ; 

: settit ( str dlgH -- ) swap z" TITLE" swap van zt IupStoreAttribute drop ; 
: gettit ( dlgH -- str ) z" TITLE" IupGetAttribute zcount str ; 

: settab ( str dlgH -- ) swap z" TABSIZE" swap dsc zt IupStoreAttribute drop ; 
: gettab ( dlgH -- str ) z" TABSIZE" IupGetAttribute zcount str ; 

: savetxt ( -- ) | uses globals dlgH and txtH  
 dup 1 c+ @ gettxt R rot @ gettit v! ;
| saves text of text dialog based on title .

: svtxt ." svtxt | " $.> txtH gettxt R dlgH gettit v! ." | " $.> cr ;

: closedlg dlgH IupDestroy drop  _n dup addr dlgH 2! ;


| \/ | really nothing below here  | \/ | =========== |

." | Job.f end | " cr 
