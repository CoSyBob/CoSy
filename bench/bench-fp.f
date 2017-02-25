| bench.f - sum of 5000 sines
." Sum of sin(1) + sin(2) + ... + sin(5000) (angles in radians)" cr cr

10000 constant loopsize
variable start-time

floats
finit

: smr
finit
f0
do
i s>f fsin f+
loop
;

: once
do
5001 1 smr
loop
;

: bench
loopsize 1 + 1 once
;

finit
19 sigdig !

f1 fsin 5000 s>f fsin f+ 5001 s>f fsin f-
| fdup f.      ."  numerator" cr
f1 fdup f+ fdup f1 fcos f* f-
| fdup f. ."  denominator" cr cr
f/
f. ."  answer by formula" cr cr

ms@ start-time !
bench
ms@ f. ."  answer by summing" cr
3 sigdig !
s>f start-time @ s>f f- loopsize s>f f/ f. ." milliseconds" cr


bye
