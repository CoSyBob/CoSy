| vim: ft=reva
|
| Shows a binary clock ;)
|
| Author: Danny Reinhold / Reinhold Software Services
| Reva's license terms also apply to this file.


needs ui/gui
needs ui/cd
~iup
~cd
~ui

context: ~binary-clock
~binary-clock

create colors
CD_BLUE ,
CD_YELLOW ,
253 cells allot


variable iup_hour
variable iup_minute
variable iup_second

variable cd_hour
variable cd_minute
variable cd_second


variable the-hour
variable the-minute
variable the-second

variable mytimer


: init-dialog
  dialog[
    " The current time:" label[  " 200x" size  ]w
    hboxs[
      canvas[  expand  dup iup_hour   !  ]w  " :" label[ ]w
      canvas[  expand  dup iup_minute !  ]w  " :" label[ ]w
      canvas[  expand  dup iup_second !  ]w
    ]c
    hboxs[  " Quit!" button[ action[ ." bye" cr  gui-close ]a  ]w  ]c
  ]d
;


| updates the variables that hold the hour, minute and second resp.
: update-time
  time&date
  3drop
  the-hour   !
  the-minute !
  the-second !
;


variable width
variable height

: get-size
  width height 0 0 cd-get-canvas-size drop
;

3 constant d

: digit-width ( nof-digits canvas-width -- digit-width )
  over 1+ d * - swap /
;

: xmin-and-xmax ( nof-digits i -- xmin xmax )
  swap width @ digit-width  | i digit-width
  swap dup 1+ d *           | digit-width i ((i+1)*d)
  >r over * r> +            | digit-width xmin
  swap over +               | xmin xmax

| now translate it - we draw from right to left...
  width @ swap -  | xmin xmax'
  swap width @ swap - swap | xmin' xmax'
;

: get-box-coords ( nof-digits i -- xmin xmax ymin ymax )
  get-size

  xmin-and-xmax
  d height @ d -
;


: draw-digit ( nof-digits i 0|1  -- )
  if CD_BLUE else CD_YELLOW then | color
  cd-foreground drop

  CD_SOLID cd-interior-style drop

  get-box-coords cd-box drop
;


| draws the value n in binary form with m digits into the currently active cd canvas
variable v
: draw-binary ( m n -- )
  v !
  dup 1 swap   | m 1 m
  0do
    2dup  v @ and not not
    i swap  draw-digit
    2 *
  loop
  drop
;


: draw-hour
  update-time

  5 the-hour @  draw-binary
;


: draw-minute
  update-time

  6 the-minute @  draw-binary
;


: draw-second
  update-time

  6 the-second @  draw-binary
;


: redraw-h
  cd_hour @ 0;

  cd-active-canvas >r

  cd_hour @  cd-activate drop

  CD_GRAY cd-background drop
  cd-clear drop

  draw-hour

  r> cd-activate drop
  gui-default
;
' redraw-h 16 cb: redraw_hour


: redraw-min
  cd_minute @ 0;

  cd-active-canvas >r

  cd_minute @  cd-activate drop

  CD_GRAY cd-background drop
  cd-clear drop

  draw-minute

  r> cd-activate drop
  gui-default
;
' redraw-min 16 cb: redraw_minute


: redraw-sec
  cd_second @ 0;

  cd-active-canvas >r

  cd_second @  cd-activate drop

  CD_GRAY cd-background drop
  cd-clear drop

  draw-second

  r> cd-activate drop
  gui-default
;
' redraw-sec 16 cb: redraw_second


: init-cd-canvas
  cd-context-iup  iup_hour   @  action: redraw_hour    cd-create-canvas  cd_hour   !
  cd-context-iup  iup_minute @  action: redraw_minute  cd-create-canvas  cd_minute !
  cd-context-iup  iup_second @  action: redraw_second  cd-create-canvas  cd_second !
;


::
  redraw-h
  redraw-min
  redraw-sec
  gui-default
; 16 cb: redraw

: init-timer
  timer action-cb: redraw  " 500" set-time  start-timer  mytimer !
;



: release-cd-canvas
|   cd_canvas @  cd-kill-canvas
;


~
: go  init-dialog  gui-map  init-cd-canvas show init-timer gui-main-loop  release-cd-canvas  destroy  ;

exit~ | ~
exit~ | ~test-app
exit~ | ~ui

go bye
