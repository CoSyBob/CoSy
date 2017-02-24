\ FPOUT.F   version 1.8
\
\ A Floating Point Output Words package for ANS FORTH-94
\ compliant systems.
\
\ This code is public domain.  Use at your own risk.
\
\ Main words:
\
\  Compact   Formatted   String
\  -------   ---------   ------
\    FS.       FS.R       (FS.)    Scientific
\    FE.       FE.R       (FE.)    Engineering
\    F.        F.R        (F.)     Fixed-point
\    G.        G.R        (G.)     General
\
\ Notes:
\
\ 1. An ambiguous condition exists if the value of BASE is
\    not (decimal) ten or if the character string
\    representation exceeds the size of the pictured numeric
\    output string buffer.
\
\ 2. Works on either separate floating-point stack or common
\    stack forth models.
\
\ 3. Opinions vary as to the correct display for F. FS. FE.
\    One useful interpretation of the Forth-94 Standard has
\    been chosen here.
\
\ 4. Display words that specify the number of places after
\    the decimal point may use the value -1 to force compact
\    mode.  Compact mode displays all significant digits
\    with redundant zeros and signs removed.  FS. F. FE. G.
\    are displayed in compact mode.
\
\ 5. Ideally, all but the main words should be headerless
\    or else placed in a hidden vocabulary.  Code size may
\    be reduced by eliminating features not needed e.g. if
\    REPRESENT always returns flag2=true or if CHARS is a
\    no-operation.
\
\ 6. If your REPRESENT does not return an exponent of +1
\    in the case of 0.0E it will result in multiple leading
\    zeros being displayed.  This is a bug** and you should
\    have it fixed!  In the meantime, a work-around in the
\    form of an alternate (F1) is supplied.
\
\ 7. If your REPRESENT does not blank fill the remainder
\    of the buffer when NAN or other graphic string is
\    returned then unspecified trailing characters will be
\    displayed.  Again, this is a bug** in your REPRESENT.
\    Unfortunately no work-around is possible.
\
\ 8. Manual rounding is used in instances when REPRESENT
\    can't e.g. when the whole significand is rounded up.
\
\ ** FORTH-94 is silent on this point.
\
\ History:
\
\ v1.1  15-Sep-02  es   First release
\ v1.2  14-Jan-05  es   Display decimal point if places = 0.
\                       Added (G.) G.
\ v1.3  16-Jan-05  es   Implemented compact display
\ v1.4  20-Jan-05  es   Handle NAN INF etc
\ v1.5  30-Jan-05  es   Implemented rounding. Changed (G.)
\                       G. upper limit.
\ v1.6  01-Feb-05  es   Changed (G.) to use decimal places
\                       parameter. Added G.R
\ v1.7  21-Feb-05  es   Fixed rounding error which occured
\                       under certain conditions.
\ v1.8  23-Jul-05  es   Rounder fixed & changed to IEEE.
\                       Negative zero support.

DECIMAL

\ 6 VALUE PRECISION       \ uncomment this line if you don't
                        \ already have PRECISION

CREATE FBUF             \ REPRESENT buffer
20 CHARS ALLOT          \ set this to your maximum PRECISION

0 VALUE BS#             \ buffer size
0 VALUE EX#             \ exponent
0 VALUE SN#             \ sign
0 VALUE EF#             \ exponent factor  1=FS. 3=FE.
0 VALUE PL#             \ +n  places right of decimal point
                        \ -1  compact display
0 VALUE NZ#             \ negative zero flag

CR .( Loading FPOUT... ) CR


\ trim trailing '0's
: (T0)  ( c-addr u1 -- c-addr u2 )
  BEGIN  DUP WHILE  1- 2DUP CHARS +
  C@ [CHAR] 0 -  UNTIL  1+  THEN ;

\ apply exponent factor
: (F0)  ( exp -- offset exp' )
  S>D EF# FM/MOD EF# * ;

-0.E0 FBUF 6 REPRESENT DROP  \ test REPRESENT

[IF]  ( system responds to negative zero )
  TRUE TO NZ#
[THEN]

1 = [IF] ( exponent correct )

\ float to ascii
: (F1)  ( F: r -- ) ( places -- c-addr u flag )
  TO PL#  PRECISION TO BS#
  FDUP FBUF BS# REPRESENT SWAP ( r exp flag2 sgn )
  \ save sign for negative zero systems
  [ NZ# ] [IF]  TO NZ#  [ELSE]  DROP  [THEN]
  AND ( exp & flag2 )  PL# 0< IF
    DROP PRECISION
  ELSE
    EF# 0> IF  1- (F0) DROP 1+  THEN  PL# +
  THEN
  DUP ( size ) 0= >R  1 MAX  PRECISION MIN  TO BS#
  FBUF R@ IF  PRECISION  ELSE  BS#  THEN  REPRESENT
  DUP  R> AND IF ( flag2 & size=0 )
    >R  FBUF C@  DUP [CHAR] 5 =
    FBUF PRECISION  1 /STRING (T0) NIP 0=  AND
    SWAP [CHAR] 5 <  OR
    IF    2DROP  1 NZ#  [CHAR] 0
    ELSE  SWAP 1+ SWAP  [CHAR] 1
    THEN  FBUF C!  R>
  THEN
  >R  TO SN#  1- TO EX#  FBUF BS#  -TRAILING  R> <# ;

[ELSE]

  CR .( *****  WARNING  ***** ) CR
  CR .( Your REPRESENT is buggy and does not return an  )
  CR .( exponent of +1 for 0.0E.  Please see your forth )
  CR .( supplier about having it fixed. ) CR
  CR .( In the meantime we are loading a work-around to )
  CR .( ensure the floating-point output functions )
  CR .( display correctly. ) CR
  CR .( Press any key to continue... ) KEY DROP CR CR

\ use this definition if you have a buggy REPRESENT
\ float to ascii
: (F1)  ( F: r -- ) ( places -- c-addr u flag )
  TO PL#  PRECISION TO BS#
  FDUP FBUF BS# REPRESENT SWAP ( r exp flag2 sgn )
  \ save sign for negative zero systems
  [ NZ# ] [IF]  TO NZ#  [ELSE]  DROP  [THEN]
  FBUF C@ [CHAR] 0 = IF ( r=0 )
    >R  DROP FDROP  1 NZ#  R> ( exp sgn flag2 )
  ELSE
    AND ( exp & flag2 )  PL# 0< IF
      DROP PRECISION
    ELSE
      EF# 0> IF  1- (F0) DROP 1+  THEN  PL# +
    THEN
    DUP ( size ) 0= >R  1 MAX  PRECISION MIN  TO BS#
    FBUF R@ IF  PRECISION  ELSE  BS#  THEN  REPRESENT
    DUP  R> AND IF ( flag2 & size=0 )
      >R  FBUF C@  DUP [CHAR] 5 =
      FBUF PRECISION  1 /STRING (T0) NIP 0=  AND
      SWAP [CHAR] 5 <  OR
      IF    2DROP  1 NZ#  [CHAR] 0
      ELSE  SWAP 1+ SWAP  [CHAR] 1
      THEN  FBUF C!  R>
    THEN
  THEN
  >R  TO SN#  1- TO EX#  FBUF BS#  -TRAILING  R> <# ;

[THEN]

\ insert exponent (uncomment the # if you wish to maintain
\ alignment for exponents > 99 )
: (F2)  ( exp -- )
  PL# 0< >R  DUP ABS S>D  R@ 0= IF # ( # ) THEN
  #S 2DROP  DUP SIGN  0< R> OR 0= IF [CHAR] + HOLD THEN
  [CHAR] E HOLD ;

\ insert string
: (F3)  ( c-addr u -- )
  0 MAX  BEGIN  DUP  WHILE  1- 2DUP CHARS + C@ HOLD
  REPEAT 2DROP ;

\ insert '0's
: (F4)  ( n -- )
  0 MAX 0 ?DO [CHAR] 0 HOLD LOOP ;

\ insert sign
: (F5)  ( -- )
  SN# SIGN  0 0 #> ;

\ trim trailing '0's
: (F6)  ( c-addr u1 -- c-addr u2 )
  PL# 0< IF  (T0)  THEN ;

: (F7)  ( n -- n n | n pl# )
  PL# 0< IF  DUP  ELSE  PL#  THEN ;

\ insert fraction string n places right of dec. point
: (F8)  ( c-addr u n -- )
  >R (F6)  R@ +
  (F7) OVER - (F4)     \ trailing 0's
  (F7) MIN  R@ - (F3)  \ fraction
  R> (F7) MIN (F4)     \ leading 0's
  [CHAR] . HOLD ;

\ split string into integer/fraction parts at n and insert
: (F9)  ( c-addr u n -- )
  >R 2DUP R@ MIN 2SWAP R> /STRING  0 (F8) (F3) ;

\ exponent form
: (FA)  ( F: r -- ) ( n factor -- c-addr u )
  TO EF# (F1) IF  EX# (F0) (F2) 1+ (F9) (F5)  THEN ;

\ display c-addr u right-justified in field width u2
: (FB)  ( c-addr u u2 -- )
  OVER - SPACES TYPE ;

\ These are the main words

\ Convert real number r to a string c-addr u in scientific
\ notation with n places right of the decimal point.

: (FS.)  ( F: r -- ) ( n -- c-addr u )
  1 (FA) ;

\ Display real number r in scientific notation right-
\ justified in a field width u with n places right of the
\ decimal point.

: FS.R  ( F: r -- ) ( n u -- )
  >R (FS.) R> (FB) ;

\ Display real number r in scientific notation followed by
\ a space.

: FS.  ( F: r -- )
  -1 0 FS.R SPACE ;

\ Convert real number r to a string c-addr u in engineering
\ notation with n places right of the decimal point.

: (FE.)  ( F: r -- ) ( n -- c-addr u )
  3 (FA) ;

\ Display real number r in engineering notation right-
\ justified in a field width u with n places right of the
\ decimal point.

: FE.R   ( F: r -- ) ( n u -- )
  >R (FE.) R> (FB) ;

\ Display real number r in engineering notation followed
\ by a space.

: FE.  ( F: r -- )
  -1 0 FE.R SPACE ;

\ Convert real number r to string c-addr u in fixed-point
\ notation with n places right of the decimal point.

: (F.)  ( F: r -- ) ( n -- c-addr u )
  0 TO EF#  (F1) IF
    EX# 1+ DUP PRECISION > IF
      FBUF 0 ( dummy ) 0 (F8)
      PRECISION - (F4) (F3)
    ELSE
      DUP 0> IF
        (F9)
      ELSE
        ABS (F8) 1 (F4)
      THEN
    THEN (F5)
  THEN ;

\ Display real number r in fixed-point notation right-
\ justified in a field width u with n places right of the
\ decimal point.

: F.R   ( F: r -- ) ( n u -- )
  >R (F.) R> (FB) ;

\ Display real number r in fixed-point notation followed
\ by a space.

: F.  ( F: r -- )
  -1 0 F.R SPACE ;

\ Convert real number r to string c-addr u with n places
\ right of the decimal point.  Fixed-point is used if the
\ exponent is in the range -4 to 5 otherwise use scientific
\ notation.

: (G.)  ( F: r -- ) ( n -- c-addr u )
  >R FDUP -1 (F1) DROP 2DROP  R>  EX# -4 6 WITHIN
  IF  (F.)  ELSE  (FS.)  THEN ;

\ Display real number r right-justified in a field width u
\ with n places right of the decimal point.  Fixed-point
\ is used if the exponent is in the range -4 to 5 otherwise
\ use scientific notation.

: G.R   ( F: r -- ) ( n u -- )
  >R (G.) R> (FB) ;

\ Display real number r followed by a space.  Fixed-point
\ is used if the exponent is in the range -4 to 5 otherwise
\ use scientific notation.

: G.  ( F: r -- )
  -1 0 G.R SPACE ;


1 [IF]

\ Some test words

CR CR
CR .( Loading test words... ) CR
CR .( TEST1  formatted, n decimal places )
CR .( TEST2  compact & right-justified )
CR .( TEST3  display FS. )
CR .( TEST4  display F. )
CR .( TEST5  display G. ) CR
CR .( 'n PLACES' sets decimal places for TEST1. )
CR .( SET-PRECISION - if you have it - sets max. )
CR .( significant digits displayable. )
CR CR

2VARIABLE (dw)
: d.w  ( -- dec.places width )  (dw) 2@ ;
: PLACES ( places -- ) d.w SWAP DROP (dw) 2! ;
: WIDTH  ( width -- )  d.w DROP SWAP (dw) 2! ;

5 PLACES  19 WIDTH

: T1  ( r -- )
  FDUP d.w FS.R  FDUP d.w F.R  FDUP d.w G.R  d.w FE.R ;

: TEST1  ( -- )
  CR ." TEST1 ... right-justified, "
  d.w DROP . ." decimal places" CR
  CR 1.23456E-16  T1
  CR 1.23456E-11  T1
  CR 1.23456E-7   T1
  CR 1.23456E-6   T1
  CR 1.23456E-5   T1
  CR 1.23456E-4   T1
  CR 1.23456E-3   T1
  CR 1.23456E-2   T1
  CR 1.23456E-1   T1
  CR 0.E0         T1
  CR 1.23456E+0   T1
  CR 1.23456E+1   T1
  CR 1.23456E+2   T1
  CR 1.23456E+3   T1
  CR 1.23456E+4   T1
  CR 1.23456E+5   T1
  CR 1.23456E+6   T1
  CR 1.23456E+7   T1
  CR 1.23456E+11  T1
  CR 1.23456E+16  T1
  CR ;

: T2  ( r -- )
  FDUP -1 d.w NIP FS.R  FDUP -1 d.w NIP F.R
  FDUP -1 d.w NIP G.R        -1 d.w NIP FE.R ;

: TEST2  ( -- )
  CR ." TEST2 ... right-justified, compact" CR
  CR 1.23456E-16  T2
  CR 1.23456E-11  T2
  CR 1.23456E-7   T2
  CR 1.23456E-6   T2
  CR 1.23456E-5   T2
  CR 1.23456E-4   T2
  CR 1.23456E-3   T2
  CR 1.23456E-2   T2
  CR 1.23456E-1   T2
  CR 0.E0         T2
  CR 1.23456E+0   T2
  CR 1.23456E+1   T2
  CR 1.23456E+2   T2
  CR 1.23456E+3   T2
  CR 1.23456E+4   T2
  CR 1.23456E+5   T2
  CR 1.23456E+6   T2
  CR 1.23456E+7   T2
  CR 1.23456E+11  T2
  CR 1.23456E+16  T2
  CR ;

: TEST3  ( -- )
  CR ." TEST3 ... FS." CR
  CR 1.23456E-16  FS.
  CR 1.23456E-11  FS.
  CR 1.23456E-7   FS.
  CR 1.23456E-6   FS.
  CR 1.23456E-5   FS.
  CR 1.23456E-4   FS.
  CR 1.23456E-3   FS.
  CR 1.23456E-2   FS.
  CR 1.23456E-1   FS.
  CR 0.E0         FS.
  CR 1.23456E+0   FS.
  CR 1.23456E+1   FS.
  CR 1.23456E+2   FS.
  CR 1.23456E+3   FS.
  CR 1.23456E+4   FS.
  CR 1.23456E+5   FS.
  CR 1.23456E+6   FS.
  CR 1.23456E+7   FS.
  CR 1.23456E+11  FS.
  CR 1.23456E+16  FS.
  CR ;

: TEST4  ( -- )
  CR ." TEST4 ... F." CR
  CR 1.23456E-16  F.
  CR 1.23456E-11  F.
  CR 1.23456E-7   F.
  CR 1.23456E-6   F.
  CR 1.23456E-5   F.
  CR 1.23456E-4   F.
  CR 1.23456E-3   F.
  CR 1.23456E-2   F.
  CR 1.23456E-1   F.
  CR 0.E0         F.
  CR 1.23456E+0   F.
  CR 1.23456E+1   F.
  CR 1.23456E+2   F.
  CR 1.23456E+3   F.
  CR 1.23456E+4   F.
  CR 1.23456E+5   F.
  CR 1.23456E+6   F.
  CR 1.23456E+7   F.
  CR 1.23456E+11  F.
  CR 1.23456E+16  F.
  CR ;

: TEST5  ( -- )
  CR ." TEST5 ... G." CR
  CR 1.23456E-16  G.
  CR 1.23456E-11  G.
  CR 1.23456E-7   G.
  CR 1.23456E-6   G.
  CR 1.23456E-5   G.
  CR 1.23456E-4   G.
  CR 1.23456E-3   G.
  CR 1.23456E-2   G.
  CR 1.23456E-1   G.
  CR 0.E0         G.
  CR 1.23456E+0   G.
  CR 1.23456E+1   G.
  CR 1.23456E+2   G.
  CR 1.23456E+3   G.
  CR 1.23456E+4   G.
  CR 1.23456E+5   G.
  CR 1.23456E+6   G.
  CR 1.23456E+7   G.
  CR 1.23456E+11  G.
  CR 1.23456E+16  G.
  CR ;

[THEN]

\ end
