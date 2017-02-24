: fib 00; dup 2 <if drop 1 ;; then 1- dup fib swap 1- fib + ;
| ." Calculating the 35th Fibonacci number using recursion... " 35 fib . cr bye

: dofibs
	0do
		." Fibonacci number " i . ." is " i fib . cr
	loop
	;

10 dofibs
