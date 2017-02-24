| *********************************************************** |
| Text decoder from DOS(cp-866) to old matrix printer         |
| 'Robotron 6313' with 'russian charset' by Pavel Sechanov.   |
| 2004 - GP-Forth compiler v.92.9                             |
| 2006 - adapted for Reva 6.0                                 |
| Example of file-io and table processing                     |
| *********************************************************** |

16 base !
create xtable
  0 1, 1 1, 2 1, 3 1, 4 1, 5 1, 6 1, 7 1,
  8 1, 9 1, a 1, b 1, c 1, d 1, e 1, f 1,
  10 1, 11 1, 12 1, 13 1, 14 1, 15 1, 16 1, 17 1,
  18 1,  19 1,  1a 1,  1b 1,  1c 1,  1d 1,  1e 1,  1f 1,
  20 1,  21 1,  22 1,  23 1,  24 1,  25 1,  26 1,  27 1,
  28 1,  29 1,  2a 1,  2b 1,  2c 1,  2d 1,  2e 1,  2f 1,
  30 1,  31 1,  32 1,  33 1,  34 1,  35 1,  36 1,  37 1,
  38 1,  39 1,  3a 1,  3b 1,  3c 1,  3d 1,  3e 1,  3f 1,
|  @,   A,   B,   1,   D,   E,   F,   G,
  40 1,  41 1,  42 1,  43 1,  44 1,  45 1,  46 1,  47 1,
|  H,   I,   J,   K,   L,   M,   N,   O,
  48 1,  49 1,  4a 1,  4b 1,  4c 1,  4d 1,  4e 1,  4f 1,
|  P,   Q,   R,   S,   T,   U,   V,   W,
  50 1,  51 1,  52 1,  53 1,  54 1,  55 1,  56 1,  57 1,
|  X,   Y,   Z,   [,   |,   ],   ^,   _,
  58 1,  59 1,  5a 1,  5b 1,  5c 1,  5d 1,  5e 1,  5f 1,
|  `,   a,   b,   1,   d,   e,   f,   g,
  60 1,  61 1,  62 1,  63 1,  64 1,  65 1,  66 1,  67 1,
|  h,   i,   j,   k,   l,   m,   n,   o,
  68 1,  69 1,  6a 1,  6b 1,  6c 1,  6d 1,  6e 1,  6f 1,
|  p,   q,   r,   s,   t,   u,   v,   w,
  70 1,  71 1,  72 1,  73 1,  74 1,  75 1,  76 1,  77 1,
|  x,   y,   z,   {,   |,   },   ~,
  78 1,  79 1,  7a 1,  7b 1,  7c 1,  7d 1,  7e 1,  7f 1,

|  =,   ?,   -,   ?,   ?,   ?,   ?,   ?,
  41 1,  80 1,  42 1,  81 1,  82 1,  45 1,  83 1,  84 1,
|  ?,   L,   L,   L,   -,   -,   -,   ?,
  85 1,  86 1,  4b 1,  87 1,  4d 1,  48 1,  4f 1,  88 1,
|  ?,   ?,   ?,   ?,   ?,   ?,   ?,   ?,
  50 1,  43 1,  54 1,  89 1,  8a 1,  58 1,  8b 1,  8c 1,
|  ?,   ?,   ?,   ?,   ?,   ?,   ?,   ?,
  8d 1,  8e 1,  8f 1,  90 1,  91 1,  92 1,  93 1,  94 1,
|  =,   ?,   -,   ?,   ?,   ?,   ?,   ?,
  61 1,  95 1,  96 1,  97 1,  98 1,  65 1,  99 1,  9a 1,
|  ?,   L,   L,   L,   -,   -,   -,   ?,
  9b 1,  9c 1,  9d 1,  9e 1,  9f 1,  a0 1,  6f 1,  a1 1,
|  ?,   ?,   ?,   ?,   ?,   ?,   T,   T,
  b0 1,  b1 1,  b2 1,  b3 1,  b4 1,  b5 1,  b6 1,  b7 1,
|  T,   ?,   ?,   ?,   +,   +,   +,   N,
  b8 1,  b9 1,  ba 1,  bb 1,  bc 1,  bd 1,  be 1,  bf 1,
|  ?,   ?,   ?,   ?,   ?,   ?,   ?,   ?,
  c0 1,  c1 1,  c2 1,  c3 1,  c4 1,  c5 1,  c6 1,  c7 1,
|  ?,   ?,   ?,   ?,   ?,   ?,   ?,   ?,
  c8 1,  c9 1,  ca 1,  cb 1,  cc 1,  cd 1,  ce 1,  cf 1,
|  ?,   ?,   ?,   ?,   ?,   ?,   ?,   ?,
  d0 1,  d1 1,  d2 1,  d3 1,  d4 1,  d5 1,  d6 1,  d7 1,
|  ?,   ?,   ?,   ?,   ?,   ?,   ?,   ?,
  d8 1,  d9 1,  da 1,  db 1,  dc 1,  dd 1,  de 1,  df 1,
|  ?,   ?,   ?,   ?,   ?,   ?,   ?,   ?,
  70 1,  63 1,  a2 1,  a3 1,  a4 1,  78 1,  a5 1,  a6 1,
|  ?,   ?,   ?,   ?,   ?,   ?,   ?,   ?,
  a7 1,  a8 1,  a9 1,  aa 1,  ab 1,  ac 1,  ad 1,  ae 1,
|  ?,   ?,   ?,   ?,   ?,   ?,   ?,   ?,
  45 1,  65 1,  f2 1,  f3 1,  ee 1,  ee 1,  49 1,  69 1,
|  ?,   ?,   ?,   ?,   ?,   ?,   ?,
  49 1,  69 1,  fa 1,  fb 1,  fc 1,  fd 1,  fe 1,  ff 1,
|

10 base !

8192 constant bufsize
xtable bufsize + constant buffer
variable handle

: errquit ( --> )              | error exit
   cr ." exiting . . ." cr cr
quote %
Recoder from DOS(cp-866) to printer 'Robotron 6313' by P.Sechanov, 2006
usage:
 robotron infile [>outfile]
   - infile = the file to recode from dos(cp-866) to robotron (russian set)
   - [>outfile] = optional parametr, you can redirect
                  result to outfile ( to PRN for example.)
powered by reva %
type 
revaver type
."  (ron@ronware.org)"
bye ;

: decode  0 do buffer i + dup c@ xtable + c@ swap c! loop ;

: main
   argc 1- 0if errquit then
   1 argv  open/r
   ioerr @                     | get error code

   if                          | open_file error
      cr ." Cannot open source file"
      errquit                  | error exit
   then

   handle !
   repeat
      | read to buffer [bufsize] bytes from file [handle]

      buffer bufsize handle @ read
      ioerr @                  | get error code

      if                       | read_file error
         cr ." Source file read error"
         errquit               | error exit
      then

      dup >r                   | really readed size

      if                       | readed > 0 ?
         | decode the buffer
         r@ decode

         | write buffer to stdout ( or prn or file )
         buffer r@ stdout write
      then

      r>                       | restore really readed size
      bufsize <                | compare real_buf_size and buf_size
      not
   while                       | false - eof, true - go repeat
   handle @ close              | close source file
   bye
;

' main in~ ~sys onstartup

1 [IF]
." Creating the robotron program..."
" robotron" makeexename (save) ." done!" bye
[THEN]

