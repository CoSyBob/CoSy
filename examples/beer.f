| "99 bottles of beer on the wall"
| adapted from http://www.99-bottles-of-beer.net/language-forth-793.html

::   dup . ." bottles" ;
::       ." 1 bottle"  ;
:: ." no more bottles" ;
create bottles , , ,

: .bottles  dup 2 clamp cells bottles + @execute ;
: .beer     .bottles ."  of beer" ;
: .wall     .beer ."  on the wall" ;
: .take     ." Take one down and pass it around" ;
: .cr ." ." cr ;
: .verse    .wall ." , " .beer .cr
         1- .take ." , " .wall .cr ;
: beers   0; cr .verse beers ;

99 beers
