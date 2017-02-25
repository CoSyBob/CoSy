
| =============================================== |
|\/ MATH \/|

: pi* fpi f* ;		| this is the monadic circle fn in APL

: gcd	( a b -- c) | Jack Browns recursive  greatest common divisor 
    dup if swap over mod gcd else drop then ;
 | From http://ronware.org/reva/wiki/index.php/Intermediate_Tutorial

 
 
|/\ MATH /\|
| =============================================== |

| Exponentiation by squaring
| See http://ronware.org/reva/viewtopic.php?id=341 
|  from | http://en.wikipedia.org/wiki/Exponentiating_by_squaring

0 [IF]    | Ruby version  
def power(x,n)
  result = 1
  while n.nonzero?
    if n.modulo(2).nonzero?
      result = result * x
      n = n-1
    else
      x = x*x
      n = n/2
    end
  end
  return result
end


| using  aux  stack 
: i^n ( i n -- i^n ) | converted from Ruby on
    | http://en.wikipedia.org/wiki/Exponentiating_by_squaring
  dup 0if 2drop 1 ;; then
  1 >aux  repeat 
   dup 2 mod
   if over aux> * >aux  1-
    else swap dup * swap 2/ 
   then 
   dup while   
   2drop aux> ;

[THEN]

 |  using  put  ( and --abcab )
 
: i^n ( i n -- i^n )
  dup 0if 2drop 1 ;; then
  1 -rot repeat 
   dup 2 mod
   if --abcab * 2 put 1-
   else swap dup * swap 2/ 
   then 
   dup while   
   2drop ;
