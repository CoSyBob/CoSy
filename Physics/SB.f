| \/ | See Wed.Apr,20160420 | \/ |
: sb ( -- StefanBoltzmanConstant ) 5.6704e-8 _f ;   

: P>Tsb ( Power -- Temperature ) sb %f .25 _f ^f ; | SB power to temperature

: dP>Tsb ( Power -- dT ) sb %f .75 _f ^f sb 4. _f *f *f 1%f ; 
|  derivative of T at a specific Power(s) 

: T>Psb ( P -- T ) 4. _f ^f 5.6704e-8 _f *f ;