needs ui/gui

with~ ~ui
with~ ~iup

: dlg
  dialog[
    " My Frame!" frame[
      hboxs[
        " My Label!" label[  " 50x10" size  ]w
        text[  expand-horizontal  ]w
      ]c
    ]fr
    spacer
    hboxs[  " Quit!" button[  action[ ." bye" cr  gui-close ]a  ]w  ]c
  ]d  " A simple dialog" title
;

: go  dlg  show  gui-main-loop  destroy  ;

without~ 
without~ 

go bye
