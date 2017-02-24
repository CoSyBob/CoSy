needs net/cgi
~cgi
with~ ~params

: br ." <br>" ;


: show-header
  quote *
<html><head><title>Test output</title></head><body>
* type
;

: show-footer
  quote *
</body></html>
  * type
;

| just a primitive check - not good enough for real world usage...
: verify-params ( -- flag )
  " attr1" find-param
  " attr2" find-param and
  " attr3" find-param and
  " attr4" find-param and
  " attr5" find-param and
dup 0if ." <h1> error - something is strange with the cgi params...</h1>" then
;

| ' a in~ ~sys onstartup
| save mycgi.exe

show-header

verify-params [IF]
  ." <b>attr1:</b> " attr1 type ." <br>"
  ." <b>attr2:</b> " attr2 type ." <br>"
  ." <b>attr3:</b> " attr3 type ." <br>"
  ." <b>attr4:</b> " attr4 type ." <br>"
  ." <b>attr5:</b> " attr5 type ." <br>"
[THEN]

show-footer
bye

