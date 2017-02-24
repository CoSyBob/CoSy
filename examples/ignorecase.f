| vim: ft=reva :
|
| Author: Danny Reinhold / Reinhold Software Services
| Reva's license terms also apply to this file.

context: ~nocase

| Finds a word - regardless of its case
:: ( a n -- dict | a n 0 )
  last @ 00; drop
  {
    cell- >r 2dup r@   | a n a n dict   r: dict
    >name count | a n a n a' n'
    cmpi
    r> swap | a n dict cmp-result
    0if
      >r 2drop r> 0 false
    else
      drop true
    then
  }
  last
  iterate

  dup 0if drop else 0 then
; setfind~ ~nocase

~nocase
: foo ." bar!" cr ;
exit~
: foo ." BAR..." cr ;

." words in context ~nocase: " words~ ~nocase
." Testing the ~nocase context: " cr
." Looking for 'foo':" in~ ~nocase foo
." Looking for 'Foo':" in~ ~nocase Foo
." Looking for 'fOo':" in~ ~nocase fOo
." Looking for 'FOO':" in~ ~nocase FOO
." Testing the ~ context: " cr
." Looking for 'foo':" foo
." Looking for 'Foo':" Foo
