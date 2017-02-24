| application - how to create an executable in reva

| released into the public domain
| 22-Oct-2006 mcarter created - confirmed working with 6.0.13


| ------------------------------------------------------------------
| example main routine - although the name is arbitrary

: main | choose a suitable name for the main function - "main" seems fine
    ." a Reva executable with " argc . ." argument(s):" cr
    argc 0 do i . i argv type cr loop | echo the arguments
;

| ------------------------------------------------------------------
| build the executable

| NOTE: The word "appstart" is in the context "~sys"
with~ ~sys

| OPTION A: Ron's preferred way: just toggle between 0 and 1 
| as appropriate

1 [IF] | make an exe when set to 1; use 0 otherwise
    ' main is appstart
    " application" makeexename (save) bye
[ELSE]
| OPTION B: Mark's way: execute the following word to create
| an executable (again, you could call the word whaever you want)
: makeexe
    " ' main is appstart" eval  
    " \" application\" makeexename (save) bye" eval
;
[THEN]

