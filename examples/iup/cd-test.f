| vim: ft=reva
|
| Simple test for the combination of IUP and CD in one application
|
| Author: Danny Reinhold / Reinhold Software Services
| Reva's license terms also apply to this file.

needs callbacks
needs ui/gui-iup
needs ui/cd

~cd
~iup
~ui

context: ~test-app
~test-app

create bitmap
inline{
  01 01 01 01 01 01 01 01
  01 00 00 01 01 00 00 01
  01 00 00 01 01 00 00 01
  01 01 01 01 01 01 01 01
  01 01 01 01 01 01 01 01
  01 00 00 01 01 00 00 01
  01 00 00 01 01 00 00 01
  01 01 01 01 01 01 01 01
}

create colors
CD_BLUE ,
CD_YELLOW ,
253 cells allot

::  gui-close  ; 16 cb: quit

variable iup_canvas
variable cd_canvas
variable mybitmap


: init-dialog
  dialog[
    " Below is an IupCanvas acting as a CD canvas..." label[ ]w
    canvas[  expand  dup iup_canvas !  ]w
    hboxs[  " Quit!" button[ action: quit ]w  ]c
  ]d
;


::
  cd_canvas @ 0;

  cd-active-canvas >r

  cd_canvas @  cd-activate drop

  CD_GRAY cd-background drop
  cd-clear drop

  CD_BLUE cd-foreground drop
  CD_DOTTED  cd-line-style drop
  0 0 30 30 cd-line drop

  CD_DIAMOND cd-mark-type drop
  40 10 cd-mark drop

  CD_SOLID cd-interior-style drop
  60 90 0 20 cd-box drop

  CD_RED cd-foreground drop
  CD_CONTINOUS cd-line-style drop
  0 0 10 10 cd-vector-text-direction drop
  100 10 z" This is a sample vector text!" cd-vector-text drop

  mybitmap @  70 70 32 32  cd-put-bitmap  drop

  r> cd-activate drop
  gui-default
; 16 cb: redraw


: init-cd-canvas
  cd-context-iup
  iup_canvas @  action: redraw
  cd-create-canvas  cd_canvas !
  8 8 CD_MAP bitmap colors cd-init-bitmap-map  mybitmap !
;


: release-cd-canvas
|   cd_canvas @  cd-kill-canvas
  mybitmap @ cd-kill-bitmap drop
;


~
: go  init-dialog  gui-map  init-cd-canvas show  gui-main-loop  release-cd-canvas  destroy  ;

exit~ | ~
exit~ | ~test-app
exit~ | ~ui

go bye
