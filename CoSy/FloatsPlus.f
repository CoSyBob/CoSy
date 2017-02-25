
~floats

| changed :
: fnip inline{ dd d9 } ; 	|  fstp st1 

: f1 ( -- f:1.0 ) inline{ d9 e8 }  ;inline

|  /\ comment fixed .

| New 

: 1/f  inline{ d9 e8 d9 c9 de f9 } ;inline	| fld1 fxch fdivrp

: f/2 ( f: a -- a/2 )  
  asm{ 
   fld1
   fadd  st, st
   fxch
   fdivrp
  } ;
  
: fcosec		| ( F: f -- cosec(f) )
  fsin 1/f  ;

: fsec          | F: f -- sec(f)
  fcos 1/f  ;

: fcotan        | f: f -- cot(f)
  ftan 1/f  ;


: fln		| F: f -- ln(f) | Floating point log base e. 
 asm{
  fldln2
  fxch
  fyl2x
 } ;

: f2^ ( f:y f:x -- f:x^y )
    asm{
        fld  st            ;   ylogx, ylogx
        frndint         ; round it to an integer
                        ; ylogx, int[ylogx]
        fsub st1, st0    ; ylogx-int[ylogx] (= z), int[ylogx]
        fxch            ; int[ylogx], z
        f2xm1            ; get the fractional power of 2 (minus 1)
                        ; int[ylogx], 2^z-1
        fld1            ; int[ylogx], 2^z-1, 1
        faddp st1,st    ; int[ylogx], 2^z
        fscale            ; add the integer in ST(1) to the exponent of ST(0)
                        ; effectively multiplying the content of ST(0) by 2int
                        ; and yielding the final result of xy:
                        ; int[ylogx], x^y
        fstp st1        ; fnip 
    } ;

0 [IF]
: f^ ( f:y f:x -- f:x^y )
    asm{
        fyl2x            ;    st0 = log(st0) * st1 = y log(x)
        fld  st            ;   ylogx, ylogx
        frndint         ; round it to an integer
                        ; ylogx, int[ylogx]
        fsub st1, st0    ; ylogx-int[ylogx] (= z), int[ylogx]
        fxch            ; int[ylogx], z
        f2xm1            ; get the fractional power of 2 (minus 1)
                        ; int[ylogx], 2^z-1
        fld1            ; int[ylogx], 2^z-1, 1
        faddp st1,st    ; int[ylogx], 2^z
        fscale            ; add the integer in ST(1) to the exponent of ST(0)
                        ; effectively multiplying the content of ST(0) by 2int
                        ; and yielding the final result of xy:
                        ; int[ylogx], x^y
        fstp st1        ; fnip 
    } ;
[THEN]

: f^ inline{ D9 F1 D9 C0 D9 FC DC E9 D9 C9 D9 F0 D9 E8 DE C1 D9 FD DD D9 } ;


: fexp inline{ D9 EA DE C9 } f2^ ;	| FLDL2E FMULP ... 


: fsinh         | F: f -- sinh(f) | (e^x - 1/e^x)/2
  fexp  fdup 1/f f-  f/2  ;

: fcosh         | F: f -- cosh(f) | (e^x + 1/e^x)/2
  fexp  fdup 1/f f+  f/2  ;

: ftanh         | F: f -- tanh(f) | (e^x - 1/e^x)/(e^x + 1/e^x)
  fdup 1/f  fover fover f-
  frot frot f+  f/ ;

: fasinh        | F: f -- asinh(f) | ln(f+sqrt(1+f*f))
  fdup
  fdup f*  f1 f+  fsqrt
  f+  fln  ;

: facosh        | F: f -- acosh(f) | ln(f+sqrt(f*f-1))
  fdup
  fdup f*  f1 f-  fsqrt
  f+  fln  ;

: fatanh        | F: f -- atanh(f) ; ln((1+f)/(1-f))/2
  f1 fover f+  f1 frot f-  f/
  fln  f/2  ;

exit~
  
|||


def: 1/f
ctx: ~floats
stack: float: a -- reciprical(a)
desc: @
	Replaces FTOS with reciprical 
@

def: fcosec
ctx: ~floats
stack: float: a -- cosecant(a)
desc: @
	Replaces FTOS with cosecant 
@


def: fsec
ctx: ~floats
stack: float: a -- seceant(a)
desc: @
	Replaces FTOS with secant 
@

def: fcotan
ctx: ~floats
stack: float: a -- cotan(a)
desc: @
	Replaces FTOS with cotangent 
@

def: fexp
ctx: ~floats
stack: float: a -- e^a   
desc: @
	Replaces FTOS with e raised to the a 
@

def: fsinh
ctx: ~floats
stack: float: a --  sinh(a) | (e^a - 1/e^a)/2
desc: @
	Replaces FTOS with hyberbolic sine . 
@

def: fcosh
ctx: ~floats
stack: float: a --  cosh(a) | (e^a + 1/e^a)/2
desc: @
	Replaces FTOS with hyberbolic cosine . 
@

def: ftanh
ctx: ~floats
stack: float: a --  tanh(a) | (e^a - 1/e^a)/(e^a + 1/e^a)
desc: @
	Replaces FTOS with hyberbolic tangent . 
@

def: fasinh
ctx: ~floats
stack: float: a --  asinh(a) | ln(a+sqrt(1+a*a))
desc: @
	Replaces FTOS with hyberbolic arcsine . 
@

def: facosh
ctx: ~floats
stack: float: a --  acosh(a) | ln(a+sqrt((a*a)-1))
desc: @
	Replaces FTOS with hyberbolic arccosine . 
@

def: fatanh
ctx: ~floats
stack: float: a --  atanh(a) ; ln((1+a)/(1-a))/2
desc: @
	Replaces FTOS with hyberbolic arctangent . 
@

