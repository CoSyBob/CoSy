| vim: ft=reva
|
| hello world example with the "later" control structure...


: hello  later ."  world!" ;
: world!  ." Hello" ;

: greet hello world! ;

greet
bye
