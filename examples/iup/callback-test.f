| A simple test for my new GUI library
|
| Author: Danny Reinhold / Reinhold Software Services
| Reva's license terms also apply to this file.

needs ui/gui

~iup
~ui

context: ~test-app
~test-app


: init-dlg
  dialog[
    " Quit!" button[ action[ ." Inside callback!" cr  gui-close ]a  ]w
  ]d  " A simple dialog" title
;

~
: go init-dlg show gui-main-loop destroy ;
exit~ | ~

exit~ | ~test-app
exit~ | ~ui


go bye
