| vim: ft=reva
|
| Simple test for the combination of IUP and CD in one application
|
| Author: Danny Reinhold / Reinhold Software Services
| Reva's license terms also apply to this file.
|
| This code is mainly based on the brownian.f example
| developed mainly by blippy and myself in the
| Reva forum...

needs ui/gui
needs ui/cd
needs random/simple

context: ~test-app
~test-app

with~ ~ui
with~ ~iup
with~ ~cd

40 value nof-particles
| for each particle: x y markertype r g b
create positions  nof-particles 6 * cells allot


::  gui-close  ; 16 cb: quit

variable mydialog
variable iup_canvas
variable cd_canvas
variable mytimer

variable width
variable height

: within ( n min-val max-val -- n ) -rot max min ; | constrain n in [min-val..max-val]
: x+- ( n -- n ) -10 10 choose[] + 2 width @ within ;
: y+- ( n -- n ) -10 10 choose[] + 2 height @ within ;
: px@ ( a -- n ) @ ;
: py@ ( a -- n ) cell+ @ ;
: pm@ ( a -- n ) cell+ cell+ @ ;
: px! ( a n -- ) swap ! ;
: py! ( a n -- ) swap cell+ ! ;
: pm! ( a n -- ) swap cell+ cell+ ! ;
: cc ( a -- )  0 255 chooser swap !  ;
: colorize ( a -- )  cell+ cell+ cell+  dup cc  cell+ dup cc  cell+ cc ;


: x+-! ( a -- ) dup px@  x+-  px! ;
: y+-! ( a -- ) dup py@  y+-  py! ;

: get-address ( n -- a ) 6 * cells positions + ;
: get-data ( n -- x y marker r g b )
  get-address  dup
  >r px@ 
  r@ py@ 
  r@ pm@
  r> cell+ cell+ cell+
  dup @
  swap cell+ dup @
  swap cell+ @
;

: init-particle  get-address  dup >r 40  px!  r@ 20 py!  r@ CD_DIAMOND pm!  r> colorize ;
: init nof-particles 0 do i init-particle loop ;

: perturb ( n --)  dup  get-address  dup >r x+-!  r@ y+-!  9 mod r> swap pm! ;


: draw-particle ( n -- )
  get-data
  rot << 16  rot << 8  or or cd-foreground drop
  cd-mark-type drop
  cd-mark drop
;


: draw-particles
  nof-particles 0 do  i draw-particle  loop
;


: do-redraw
  cd_canvas @ 0;

  cd-active-canvas >r


  cd_canvas @  cd-activate drop

  CD_GRAY cd-background drop
  cd-clear drop

  CD_BLUE cd-foreground drop
  draw-particles

  r> cd-activate drop
;

:: do-redraw  gui-default ; 16 cb: redraw

:: 2 cb-param height !  1 cb-param width !  gui-default ; 16 cb: resize

:: nof-particles 0 do i perturb loop  do-redraw  gui-default ; 16 cb: jiggle


: init-dialog
  dialog[
    " Below is an IupCanvas acting as a CD canvas..." label[ ]w
    canvas[  expand  dup iup_canvas !  ]w
    hboxs[  " Quit!" button[ action: quit ]w  ]c

    dup mydialog !
  ]d

  timer action-cb: jiggle  " 10" set-time  start-timer  mytimer !
;


: init-cd-canvas
  cd-context-iup
  iup_canvas @  action: redraw  resize-cb: resize
  cd-create-canvas  cd_canvas !
;


: release-cd-canvas
|   cd_canvas @  cd-kill-canvas
;


: go
  init
  init-dialog
  gui-map
  init-cd-canvas
  show
  gui-main-loop
  release-cd-canvas
  destroy
  mytimer @ stop-timer drop
;
to~ ~ go

without~ | ~ui

exit~ | ~test-app

go bye
