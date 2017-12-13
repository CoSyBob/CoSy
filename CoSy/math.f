
| =============================================== |
." | \\/ MATH \\/ | "
 

: pi fpi _f ;

: fpi* fpi f* ;		| this is the monadic circle fn in APL

: rad fpi 180. f/ _f ; 

: gcd	( a b -- c) | Jack Browns recursive  greatest common divisor 
    dup if swap over mod gcd else drop then ;
 | From http://ronware.org/reva/wiki/index.php/Intermediate_Tutorial

| \/ | ===== |  Most basic euclidian computations | ======== | \/ |

: dot *f +/ ;
| f( -1 0 1 )f f( 1 2 3 )f dot  |>| 2.00 
: norm^2 dup rep dot ;
|   f( -1 0 1 )f norm^2 		|>| 2.00 
: norm norm^2 sqrtf ;

| /\ MATH /\ |
| =============================================== |
| \/ | Stats | \/ |
| cf Arthur Whitney's K math functions | 
|  http://cosy.com/K/Math_AW.txt

: avgf  1p> +/ R@ rho i>f %f 1P> ; 

: var 1p> ^2f avgf R@ avgf ^2f -f 1P> ;
: dev var sqrtf ; 

: cov 2p> *f avgf LR@ ['] avgf on2 *f -f 2P> ;
: cor 2p> cov LR@ ['] dev on2 *f %f 2P> ; 

| 20 _iota i>f .. reverse cor 10 _i fmtnF
| need to deal w rounding . 

| /\ | Stats | /\ |
| =============================================== |

needs random/gm
 
: _rand_ ( n -- a ) dup intVecInit >aux
   0 ?do rand aux@ i ii! loop aux> ; 
 
: _rand ( i n -- ) | n rands in  i iota raw 
   dup intVecInit >aux
   0 ?do dup rand um* nip aux@ i ii! loop drop aux> ; 

: rand ( i n -- iv )  2p L@ i_ R@ i_ _rand 2P> ; 	| n rands in  i iota . 

: _perm ( n -- [ random permutation of n items ] )
  dup _iota >aux dup dup _rand 
  swap 0 ?do dup i ii@ aux@ i ii@
  swap aux@ swap ix xchg aux@ i ii! loop free aux> ; 
| not sure who in the Reva mail group offered this algo . Neat because it only
| requires 1 rand , but I don't think it complete and uniform . see
| http://math.stackexchange.com/questions/1003779/show-whether-this-algorithm-produces-a-uniform-random-permutation

: factors ( n _i -- factors ) .. i>f sqrtf f>i iota i1 +i .. --bac _modi 0=i & at ;
| Returns smaller factors of n . See  Thu.Nov,20171130 
| eg : | 60 _i factors     |>| 1 2 3 4 5 6 

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

." | /\\ MATH /\\ | "