| Simple example for the usage of file dialogs...
|
| Author: Danny Reinhold / Reinhold Software Services
| Reva's license terms also apply to this file.


needs ui/gui

context: ~myapp
~myapp

with~ ~ui
with~ ~iup
::
  file-open-dialog[
    " *.dbf;abc*.txt" attr: FILTER
    " YES" attr: MULTIPLEFILES
  ]fd
  popup
  getval
  type cr
  gui-default
; 64 cb: file-dlg

: dlg
  dialog[
    " File" button[ action: file-dlg ]w
    hboxs[ " Quit" button[ action[ gui-close ]a ]w ]c
  ]d " File dlg example" title
;


: go dlg show gui-main-loop destroy ;
to~ ~ go


without~ | ~ui
exit~    | ~myapp



