| Another simple test for the new GUI library
|
| Author: Danny Reinhold / Reinhold Software Services
| Reva's license terms also apply to this file

needs ui/gui
needs ui/gui-iup-img


context: ~test-app
~test-app

with~ ~ui
with~ ~iup

:: ." bye" cr  gui-close  ;  16 cb: quit

: define-dialog
  dialog[
    toolbar[
      " b1" button[  img-open image  ]w
      " b2" button[  img-save image  ]w
    ]t

    spacer

    hboxs[
      " Frame" frame[
          " Label1" label[ ]w
          spacer
          " Button1" button[ ]w
      ]fr
    ]c

    spacer

    hboxs[
      " Quit!" button[ action: quit ]w
    ]c

  ]d  " Simple test application" title
;


: go  define-dialog  show  gui-main-loop  destroy  ;
to~ ~ go

without~ | ~ui

exit~ | ~test-app
go bye
