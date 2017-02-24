needs date/calendar
with~ ~sys
with~ ~date

: yymmdd>fixed 100 /mod 100 /mod 2000 + -rot swap rot gregorian>fixed ;
: datediff ( yymmdd yymmdd -- days ) yymmdd>fixed swap yymmdd>fixed - ;

: main 1 argv >single drop 2 argv >single drop datediff . cr ;

' main is appstart
" datediff" makeexename (save)
