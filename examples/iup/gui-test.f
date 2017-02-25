| Simple GUI test
|
| Author: Danny Reinhold / Reinhold Software Services
| Reva's license terms also apply to this file

needs ui/gui
needs ui/gui-iup-img

context: ~test-app
~test-app

with~ ~ui
with~ ~iup

:: ." Ok, bye!" cr gui-close ; 16 cb: quit

| keyboard event handler inside an editbox
| ignore the key "e"
| and replace "a" by "b"
:: ( cb-param<handle c cstr> -- continuationcode )
  1 cb-param
  'e =if  drop  gui-ignore ;;  then
  'a =if  'b  ;;  then
  gui-default
; 16 cb: key-validate


| This is a KEY_ANY callback that also gets
| function keys from an edit box...
:: ( cb-param<handle c> -- continuationcode )
  1 cb-param
  320 =if ." F6 pressed!" cr else ." other key pressed!" cr then 
  gui-default
; 16 cb: key-any


: define-dialog ( -- dialoghandle )
  dialog[
    hboxs[
      " Label 1" label[  img-label-tecgrafpucrio image  ]w
      " Label 2" label[  img-open image  ]w
    ]c
    spacer
    hbox[
      " Label 3" label[  " 0 255 255" fgcolor  " 10 10 10" bgcolor  ]w
    ]w
    spacer
    editbox[  expand  " Type some text!" tip  action: key-validate  " Some initial text" setval  ]w
    spacer
    editbox[  expand  " Press F6!" tip  key-any-cb: key-any  " Press F6!" setval  ]w
    spacer
    matrix[ " 5" attr: NUMCOL  " 5" attr: NUMCOL_VISIBLE  " 100" attr: NUMLIN  " 10" attr: NUMLIN_VISIBLE
            " One" attr: 0:1 " Two" attr: 0:2 " Three" attr: 0:3 " Four" attr: 0:4 " Five" attr: 0:5  ]w
    spacer
    radio[
      " Toggle1" toggle[ ]w
      " Toggle2" toggle[ ]w
      " Toggle3" toggle[ ]w
    ]r
    hboxs[
      " Quit!" button[  action: quit  " Simple button action definition" tip  ]w
      spacer
      " Quit!" button[ ['] quit action  " More usual button action definition" tip  ]w
      space
      " Quit!" button[ action[ ." bye!" cr gui-close ]a  " Inline button action definition" tip  ]w
    ]c
  ]d  " My Dialog!"  title
;

: go  define-dialog  show  gui-main-loop  destroy  ;
to~ ~ go

without~ | ~ui

exit~ | ~test-app
go bye
