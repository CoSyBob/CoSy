| for numbers 1..100, print "Fizz" if multiple of 3, "Buzz" if multiple of 5,
| and "FizzBuzz" if multiple of both - otherwise, print the number
create fizzbuzz " FizzBuzz" here,
variable fizzed

: fizzbuzz? ( i a mod -- i )
	2 pick swap mod
	0if 4 type fizzed on ;then drop ;

: num?  ( i --   ) fizzed @ if space drop ;then . ;
: fizz? ( i -- i ) fizzbuzz 3 fizzbuzz? ;
: buzz? ( i -- i ) fizzbuzz cell+ 5 fizzbuzz?  ;

: fb 101 1 do fizzed off i fizz? buzz? num? loop ;

fb cr bye
