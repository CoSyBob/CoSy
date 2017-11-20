
| =============================================== |
| \/ MATH \/ |

: pi* fpi f* ;		| this is the monadic circle fn in APL

: gcd	( a b -- c) | Jack Browns recursive  greatest common divisor 
    dup if swap over mod gcd else drop then ;
 | From http://ronware.org/reva/wiki/index.php/Intermediate_Tutorial

| \/ | ===== |  Most basic euclidian computations | ======== | \/ |

: dot *f +/ ;
| f( -1 0 1 )f f( 1 2 3 )f dot  |>| 2.00 
: norm^2 dup rep dot ;
|   f( -1 0 1 )f norm^2 		|>| 2.00 
: norm norm^2 sqrtf ;
 
: cor 2p> dot LR@ ['] norm^2 on2 *f %f ;
 
 
| /\ MATH /\ |
| =============================================== |
| \/ | Stats | \/ |
cf Arthur Whitney's K math functions | 
  http://cosy.com/K/Math_AW.txt

: var 1p> ^2f favg R@ favg ^2f -f 1P> ;
: dev var sqrtf ; 
 20 _iota i>f dev

: cov 2p> *f favg LR@ ['] favg on2 *f -f 2P> ;
: cor 2p> cov LR@ ['] dev on2 *f %f 2P> ; 

 20 _iota i>f .. reverse cor 10 _i fmtnF
| need to deal w rounding . 

| /\ | Stats | /\ |
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

