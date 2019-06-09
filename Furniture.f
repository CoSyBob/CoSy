| Furniture : fns to flesh out the living area .
| Require CoSy APL object vocabulary . 
| Do NOT require R dictionary obs 
| Author: Bob Armstrong / www.CoSy.com
| Reva's license terms also apply to this file.

cr ." | Furniture begin | "

| \/ | MISC UTILS |\/|

: str>pad_ ( str -- a n ) { pad place } onvan pad count ;
| Move string < 1024 bytes to pad and free if ref count 0 . 

: dae ( v -- v ) >aux+> dup ['] rho 'm ,/ i0 <>i & at aux- ; 
| Delete All Empties . Deletes all empty , items of a list . 
| translated from K | { x @ & 0 < #:' x } |

| ( str -- str ) Delete Redundant ( all but first of sequences of )
|  blanks  in string  y 	| 20190325 | fixed 20190411 
: drb  >a "bl a@ cL "bl =c >a> 1 _rotate a> mini & a> swap dvi ;

: MV over Type@ 0if  2p R@ L@ ['] cL 'R  ,/ R@ rho cut 2P>  ;then drop ;
| Matrix to Vector . Ravels , eg : lists of strings LA inserting token RA
| , eg : "bl or "lf , as a delimiter | in K | { ( # x ) _ ,/ x ,/: y }
| Just returns simples | 20190510 |

: rho' ['] rho 'm ;  | rho on each item of list . for convenience 

| |/\| MISC UTILS |/\|

| |\/| FILE & OS FNS |\/| with CoSy args
| since  ' s"  was changed to not escape ` \ , some of these conversions are
| not needed as much .
| Note that while MS doesn't care about case , F> in particular does .


| convert all / to \ |	| 20190415
: />\  s" /" s" \" ,L ssr ; 	| probably what you want vs dosslash^ 
| 20180815 | corrected for change in ' s" 

: \>/ s" \\" s" /" ,L ssr ; 	| replaces DOS \ w RoW / .

: lf>nl "lf "nl ,L ssr ; 	| convert UNIX "lf line breaks to DOS "nl 
 				| changed names from "lf>"nl | 20190518
: nl>lf "nl "lf ,L ssr ; 	| convert DOS "lf line breaks to UNIX "n| 
| Use to convert ' res> result for saving as CoSy source file .

: include^ ( fname -- flag ) { (include) ioerr @ _i } onvan ; | returns 0 on success

: Fcreate ( fn -- fileid ) dup van fcreate ref0del ; 
 
: Fwrite ( dat fn -- )  over van --abca van foc >r> write r> close 2ref0del ;
 
: >F : Foverwrite ( str flnm ) over van --abca van foverwrite  2ref0del ;
 
: F> ( str -- str ) >r> van slurp r> ref0del
	--aab str swap nakedfree ;
| Like "slurp" but takes and returns CoSy strings and frees original .

: shell^ ( str -- str ) dup van shell ref0del ;
 
: shell> ( str -- str ) dup van shell$ --aab str swap free swap ref0del ;
    | executes str in OS returns any output . 
	| need to double \\ in strings since \ is the escape for \" .
	| see also ` dosslash^  

: dir s" dir " shell> ; 	| trumps Reva ~os dir 
: cd s" cd " shell> -1 _cut ; 

 " COSYSTARTFILE" getenv str >value COSYSTARTFILE 
 COSYSTARTFILE dup s" \" ss -1 _at i1 +i take >value CoSyDir
 
: fullCoSyFile cd COSYSTARTFILE cL ; 
: CoSyFile  COSYSTARTFILE s" \" toksplt -1 _at ; 

: start s" start C:\\Windows\\System32\\cmd.exe /k " swap cL shell^ ; 
| start DOS program in separate command shell . 

| |/\| FILE & OS FNS |/\| with CoSy args

| s" C:/4thCoSy/lib/alg/hsort" include^ >_ $.s if z" load fail : hsort " throw then
| s" C:/4thCoSy/lib/helper" include^ >_ if z" load fail helper " throw then

: forth> ( str -- str ) { ['] eval spool } onvan ;
 | evaluates str spooling and returning output . | 20160605.1138

: www ( str -- )  R s" BROWSER" v@  | open URL in BROWSER  
  swap cL shell^ ;

: WSb ( str -- bool_of_WhiteSpace ) { 33 <I _i } eachM> ['] cL across ;

: WScut ( str -- list_of_strings_split_on_WhiteSpace ) dup WSb & cut ;

: WStable ( str -- table ) ev temp ! 
   lfVM { WScut enc temp @ swap cL temp ! } eachM temp @ ;
|  converts string containing table , eg read off browser screen , to CoSy
| list of lists splitting rows on "cr"s and columns on any white space .

| ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ | 
| \/ \/ \/ Stack made with CoSy obs \/ \/ \/ |
ev refs+> variable, stk			| set stk to an empty vector 
 
: p ( obj -- ) stk @ cL  stk rplc ;		| push 
 
: P ( -- obj ) stk @			| pop
   dup i# 0if drop ev refs+> ;then		| if empty return empty
   dup dsc  swap i1 _   stk rplc  dup refs-ok ; 
| /\ /\ /\ Stack made with CoSy obs /\ /\ /\ |

| ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ | 
| \/ \/ \/ |  REF COUNTING  | \/ \/ \/ |
| These fns are useful for checking that created obs get collected .
| Useful phases are included in  ` state .
 
  0 _i 64 K* _take refs+> value AFbuf
variable AFptr 
 
: AFbufON ( -- ) 
	| note not modulo . subject to overflow . 
 { dup AFbuf vbody AFptr @>+! c+ ! } >defer AT+>
 { negate AT+> negate } >defer FT+> ;  | - adr  for freeing
 
: AFbufOFF ( -- ) undo AT+>  undo FT+> ;
 
: AF1 AFptr off  AFbufON ; 		: AF0 AFbufOFF ; 	: AF> AFbuf AFptr @ _take ; 
 
| /\ /\ /\ |  REF COUNTING  | /\ /\ /\ |

| ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ | 
| \/ \/ | Time Fns | \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ |
 
: ymd.hms_ time&date _ymd.hms_ ;  : ymd.hms ymd.hms_ str ; 
| : |ymd.hms| ymd.hms s" |" braket ; : |ymd.hms|_ |ymd.hms| str>pad_ ;
 
: _ymdhms _ymdhms_ str ;      : ymd.hm ymd.hm_ str ;
: ymdhms ( -- yyyymmdd.hhmmss ( string ) time&date _ymdhms ; 
 
: ymdhm ( -- yyyymmdd.hhmm ) ymdhm_ str ;
: |ymd.hm| ymd.hm s" | " s"  | " ,L braket ; : |ymd.hm|_ |ymd.hm| str>pad_ ;
 
| Converting  ' daysdif  used to compute days of my life to take CoSy dates
: date_ ( yyyymmdd _i -- d m y ) >r> vbody @ dtupk r> ref0del ;
: daysdif^ >r date_ r> date_ daysdif _i ; 	| 20171112 
 
| Cut text into day entries ( approximate as can be seen from def . )
 "lf s"  | ======================== | " cL refs+> value daylnTok 
 
 : daylncut ( str -- listOFstrings ) daylnTok tokcut ;

: daylnDS s" | " VM 2 _at ; | return DayStamp from ' dayln entry |
|  Thu.May,20190530 

| \/ Calendar \/ | 
 
| : dt time&date 6 s>iv ;
 
: daylns ( d m y n -- ) | outputs daylines for begining date + n days . 
 >r date>fixed _i r> _iota +i { fixed>date dayln type cr } eachM ;
| >r date>fixed _i r> _iota ['] +i aaply { fixed>date dayln type cr } eachM ;
 
| : DAYLNS ( date number -- str ) 2p L@ >_ dtupk R@ >_  
 
0 [IF]
: _jd ( v_yyyymmdd -- v_julian ) | same as K _jd except 00010101 is 1 instead of 20350101 -> 0 .  
[THEN]
 
| /\ /\ | Time Fns | /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ |

| ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ | 
| \/ \/ | partitioned string fns | \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ |

: strCmpr ( s0 s1 -- -0+ ) | returns -1 if s0 < s1 , 0 if identical up to length of shorter , 1 if s0 > s1
  2p> i#i# min 
   0do L@ i i@ R@ i i@ >sn ?dup if _i 2P> unloop ;then loop 2P i0 ; 

 "nl "nl cL refs+> value emptyLn
 | MS-DOS definition of blank line . must be changed for UNIX \n

| see 20180729
: inb ( lst tok -- lst ) 2p> rho { take R@ match } 'L ,/ 2P> ;
| bool of lines starting w tok 
 
: in 2p> --aab inb & at 2P> ;
| lines starting w tok 
 
: ninb inb 0=i ;
: nin 2p> --aab ninb & at 2P> ;
| the obvious complements 

| delete leading blanks . 20190430 
: dlb 1p> dup { 32 <> } f?m cut 1P> ;
: dtb reverse dlb reverse ; 	| delete trailing blanks  | 20190608 

| 20190203 | \/ | vocabulary found useful over the years | \/ |
: prt<f ( str tok -- PaRT_Before_First ) 2p> ss1st L@ swap take 2P> ;
: prt<=f ( str tok -- PaRT_Before_Firstincluding )
   2p> ss1st R@ rho +i L@ swap take 2P> ;
: prt>=l 2p> ['] reverse on2 prt<=f reverse  2P> ; 
: prt>l 2p> ['] reverse on2 prt<f reverse  2P> ;

: prt>f  2p> ss1st R@ rho +i L@ swap cut 2P> ;
: prt>=f 2p> ss1st L@ swap cut 2P> ;
: prt<=l 2p> ['] reverse on2 prt>=f reverse  2P> ; 
: prt>l 2p> ['] reverse on2 prt>f reverse  2P> ;
| /\ |

: braketed ( str tok0 tok1 ,L -- str ) 2p> dsc prt>=f R@ 1 _at prt<=l 2P> ;
| portion of string between but including two token strings . eg :
|   s" Gilgamesh Athorya <e9gille@hmail.com>," s" <" s" >" ,L braketed
| <e9gille@hmail.com> 

0 [IF]
: partFind ( phr str delim -- occurances ) | splits str at occurances of delim
	| and returns parts that contain phr .
  toksplt 
  refs+> >r> { "bl cL swap ssc dup i# M->I _i swap free } eachright
  ['] cL across &  r@ swap at r> refs- ;
 
: partFindBl ( phr str -- occurances )  emptyLn partFind ; 
[THEN]

| /\ /\ | partitioned string fns | /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ |
| ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ | 
| \/ \/ | miscellaneous fns | \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ |

: _dasm ( adr n -- str ) cL fmtI "bl MV s"  disassemble " cL forth> ;
| ' disassemble raised CoSy level .  n is number of cells to be disassembled . 

: _DMP> ( addr -- str ) s"  DMP " forth> ; | returns ' DMP as str

: Words ( str -- strL ) s" words " swap cL forth> blVM -2 _i cut ;
| see   s" help words" forth> | use "bl arg all words | renamed 20190529

: Xwords s" xwords " forth> "lf 2 _take toksplt dae
   { "lf toksplt 2 _take } 'm  ;
| all words in all contexts. returned  | renamed 20190529

| Reva help on Reva word returned as CoSy string | 20190225 
: Help ( word -- Reva_help_on_Reva_word ) s" help " swap cL forth> ;

| x86 assembler code of word .
: See ( word -- assembler_code ) s" see " swap cL forth> ;

: .needs> ['] .needs spool blVM i-1  _ dsc ;

: ^!! ( str -- ) dup van shell ref0del ;	| CS version of !! shell execute .

| Convert character vec ( byte to integer ) 
: c>i ( cv -- iv ) ['] _i  'm ,/ ;
|  dup Type@ TypeC <>if ref0del z" must be character " throw ;then
|  dup i# intVecInit >aux> 0 ?do dup i ib@ aux@ i ii! loop ref0del aux> ;
 
| Convert integer to character vec . 
: i>c ( iv -- cv ) dup Type@ TypeI <>if ref0del z" must be integer " throw ;then
  dup i# byteVecInit >aux> i# 0 ?do dup i ii@ aux@ i ib! loop ref0del aux> ;
| fixed missing ' i#  20180629 | absurdly slow for some reason . 180218

: ilst ( RA -- indexed_list ) | appends index to list and flips  
	1p> rho iota R@ ,L flip 1P> ;

| /\ /\ | miscellaneous fns | /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ |
| ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ | 
| \/ \/ \/ MOST MIMIMAL MATH \/ \/ \/ | 

| Set & see significant digits variable used by formatting fns . 20180702 
: _>sigdig _i : >sigdig >_ sigdig ! ; 	: sigdig> sigdig @ _i ; 

: Pi fpi _f ;

: PoT 1p R@ R@ +/ %f 1P> ; | Proportion of Total . I find very useful 

: 2sComplement i1 +i i-1 *i ; 	| useful for indexing from end   
|  s" Hello World " 12 _iota 2scmplmnt at |>|  dlroW olleH | 20180724

: c>f ( fv -- fv )  1.8 _f *f 32. _f +f ; 	| centigrade to farenheit | 20141124 
: f>c ( fv -- fv )  32. _f -f 1.8 _f %f ; 	| farenheit to centigrade | 20141124 

 | ======================================== |

| Split integer vec into positives and negatives 
: +-splt ( iv -- v ) 1p> i-1 >i refs+> >r> & R@ swap at 
	R@ r@ 0=i & at ,L r> refs- 1P> ; 

| see also | math.f |
| /\ /\ /\ |  MATH  | /\ /\ /\ |

|  : ref " notepad \\cosy\\ref.txt" shell ;

| : $^  ( sym -- ) | display var in  res 
|	dup+ " source" (sym)  R " res" (sym)  ;

| save res to value of 
| : saveres ( -- ) ;

| \/ | ARK | \/ |

| `( Type0 TypeC TypeI TypeFl TypeS TypeV TypeA TypeFv )` dup+
|  { van eval _i } eachM> ' cL across  over refs-ok  cL  R ` Types v!

." | Furniture end | " cr