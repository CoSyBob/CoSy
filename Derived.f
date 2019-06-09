| Fns requiring  ` R  .
| Author: Bob Armstrong / www.CoSy.com
| Reva's license terms also apply to this file.
| Sat.May,20070526 

cr ." | Derived begin | " 
| Words requiring ' R , Root , list
| ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

| \/ \/ | CoSy Help Words | \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ |
 
: (CShelp) ( str file -- occurrences ) F> emptyLn toksplt   
   swap con dup i# if { "nl swap cL } eachm then ;
 
: CShelpFul ( str -- refs ) | searches source files listed in 
| `( sys CoSySource )` for str and returns list of files searched 
| and source between preceding and succeeding blank lines containing  str .
  [ R ` sys v@ ` CoSySource v@ ] literal
  { >r> (CShelp) r> swap cL } eachright ;

| \/ |  | Main Help function . Return lines , delimited by empty lines 
 		| in files listed in |  ` sys Dv@ ` CoSySource v@  |
 		| which contain the phase passed
 
: :?? s" : " swap cL 	| note fall thru to  ' ?? . return only def | 20190518
: ?? CShelpFul >aux+> dup ['] rho 'm ,/ i1 >i & at refs+> aux- refs-ok>  ; 
." Help /\\ " cr | /\ |

| Returns only those file in which the phrase was found

| /\ /\ | CoSy Help System | /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ |

: saveTSclone  R COSYSTARTFILE ymdhm cL s" .csy" cL savelist ; | 20181227

| \/ \/ | Accounting tools | \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ |
| Accounting is one of the highest value uses for any computing language
| If you are good at number crunching , the numbers with the greatest return
| on crunching are ones with currency symbols attached .
| That's why , despite one early APL company being named ` STSC	for
| Scientific Time Sharing Company , even its major market was complex financial
| applications in global money center cities .

| I currently keep a simple list :
|   `( TimeStamp From To amount notes )` 
| constructed by lines like 
|    (' 20181015. _f ` PSBT ` IREA  f( 136.67 10 )f  s" acnts -792 -787 " ')
| to give an example with multiple amounts to be summed 
| 
| I then append these to a ` LedgerList in R . 
| here's a word specific to my current use , here for convenience
 
: LL_cL enc s" LedgerList"  Dv_cL ; 	| append enclosed list to ledger .
 
| eg: 
|  (' 20180909.1523 _f ` PSBT ` visa  337.34 _f  s" pif " ') LL_cL
| to post an entery directly to ` LedgerList .

| /\ /\ | Accounting tools | /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ /\ |

." | Derived end | "