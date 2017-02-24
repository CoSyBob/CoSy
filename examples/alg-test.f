needs random/gm
needs alg/stack
needs alg/htable
needs math/floats

with~ ~sys
with~ ~floats
with~ ~struct

| tools
| make prompt .s ." ok> " ;

: seed ( --)  ms@ dup 2dup seed4 ;
: -rand  ( max -- n<max)  rand swap mod ;
: rand ( max -- n<max)  00; -rand abs ;

seed

| create and fill structs
4 4 2array adam adam
101 rand 0 th ! 101 rand end !
101 rand cols rand rows rand 2ins prt cr
1 darray don don
: fil ary @ size 0do dup @ null @ =if 99 i th ins then cell+ loop drop ;
7 times fil prt cr

list linda linda
: n>list  10000 rand ins ;
18 rand 2 + times n>list prt cr

stack sam sam
: enumstack  0do i psh loop ;
{ drop 10 rand < } >defer compare                      | one method to make a bunch
10 enumstack                                           | of unique random numbers
stk @ (srt) | could also do: ' sam (srt)
prt cr

14 htable he-man he-man

: randltr  26 rand 97 + ;
: randword ( -- a u)
      5 rand 3 + scratch 2dup ( u a u a)
      tuck + swap ( u a a'a+1)
      do randltr i c! loop
      _1- 2dup c! 1+ swap ;
: $>table ( --) randword ins$ ;
: n>table  10000 rand ins ;

size times $>table prt$

| 1 dup variable, tim variable, sue
| 7 htable hum hum
| tim ins sue ins prt


| analyze
: avglength
      bucketlength occupied frac>dec ;

: .avglength
      ." avg chain " avglength 2 0 f.r ;

: (stats)
      rmvkeys size times $>table
      avglength f+ 2 s>f f/ ;
: stats ( --)
      0 s>f 200 times (stats) f. ;


.avglength cr
