~sys make prompt  .s ." ok> " ; exit~

needs os/console

macro
 : 1if p: 1- p: 0if ;
forth

alias: ]; }
alias: :[ {
alias: >< between
alias: stack stack:
alias: list variable
alias: context context:

: ver " Caravan 0.13 - a Roguelike Adventure- by macoln" ;
| •••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
|
|          ££££££££      £      £££££££         £     ££££     £££     £       £       ££££
|         £       £      £        £    £        £      ££       £      £       ££        £
|        £        £     £££       £    £       £££      £      £      £££      £££       £
|       ££              £ £       £    £       £ £      ££     £      £ £      £ ££      £
|       ££             £  £       £    £      £  £       £    £      £  £      £  ££     £
|       £              £  ££      £   £       £  ££      ££   £      £  ££     £   ££    £    
|       ££             £   £      £££££       £   £      ££   £      £   £     £    ££   £
|       ££            £ £££££     £   £      £ £££££      £  £      £ £££££    £     ££  £
|        £            £     £     £    £     £     £      ££ £      £     £    £      ££ £
|         ££      £  £      ££    £     ££  £      ££      ££      £      ££   £        ££
|          ££££££££ £££     ££££ ££££    £££££     ££££    £      £££     ££££££££       £
|
|                                                                 - a Roguelike Adventure-
| •••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••

|                               a  -- memory address (a pointer)
|                               a' -- new or modified a
|                               c  -- ascii character (glyph)
|                               c' -- new or modified c
|                               k  -- keyboard input
|                               n  -- a number
|                               t  -- truth value (-1 true, 0 false)
|                               u  -- length of a string
|                               x  -- column # in 3-D array
|                               y  -- row # in 3-D array
|                               z  -- layer # in 3-D array
|                               x+ -- incremented column #
|                               y+ -- incremented row #
|                               z+ -- incremented layer #
|                               xt -- a of a word's contents (a pointer to a function)

| •••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
|                                      ££  £££  ££ £££ ££
|                                      £-£ £-  £ _  £  £ £
|                                      ££  £££  ££ £££ £ £
|                                      •••••••••••••••••••

context ~caravan
~caravan

defer act         defer colours
defer cave-alg    defer europe        defer meander     defer meander?
defer north-alg   defer polar-alg     defer river-alg   defer road-alg
defer room-alg    defer scatter-alg   defer shave-alg   defer south-alg

: array ( size <name> -- does: a)                      | create an array
      create  cells
      allot ;
      | dup allocate dup , swap 0 fill                   | allocated to OS memory and fill with zero's
      | does> @ ;

: 3array ( length width layers <name> -- does: a)      | create a 2-byte y*x*z (3-D) array
      create  * * cells
      allot ;
      | dup allocate dup , swap 0 fill                   | and fill with zero's
      | does> @ ;

     46 value Y ( >47 causes europe to crash)          | map length
     79 value X                                        | map width
      5 value Z                                        | layers: 4-actor 3-ground 2-items 1-terrain 0-hidden

 Y X Z 3array map                                      | create a map

    200 stack x                                        | an auxiliary stack

      0 value wall                                     | wall-type
      1 value wide                                     | width and
      1 value long                                     | length of room
      0 value me                                       | ptr to current actor
      0 value keypress                                 | last key or direction input
      0 value thiswater                                | ascii value of current stream or river

     variable in-map?                                  | check if we've exited map

         list census                                   | all people
         list structures                               | all structures
         list usables                                  | all usable objects
         list events                                   | all objects that trigger events
| •••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
|                                      £££ £££ £££ £    ££
|                                       £  £ £ £ £ £    £
|                                       £  £££ £££ £££ ££
|                                      •••••••••••••••••••

: 2+  1+ 1+ ;  : 2-  1- 1- ;  : .#  (.) type ;  : ++_  inline{ ff 06 } ;  
   variable st
: .stack                                               | print contents of data stack to screen
        0 Y 3 + st @ + gotoxy st @ .# ." ." .s st ++ ;
: >x x push ;  : x> x pop ;  : x@ x peek ;  : xdrop  x> drop ;  : .x ['] . x stack-iterate ;
: xreset ( --)
        x stack-empty? not 0; drop xdrop xreset ;
: xyz>a ( x y z -- a)                                  | given x y z, get a in 2-byte array
        X Z * rot * + swap Z * + cells map + ;
: a>xyz ( a -- x y z)                                  | now the opposite
        map - 1 cells /  X Z * /mod swap Z /mod -rot ;
: ?execute ( xt-c | 0 -- c | 0)
        dup if  execute  then ;
: count-nodes ( list -- n)
        0 :[ ++_ ]; rot iterate ;
: get-node ( a -- a-node)
        cell- @ ;
: in-list? ( n list -- t)
        over 0drop; drop
        :[ @ over xor dup 0if nip dup then ]; swap iterate not ;
: print-list ( list --)
        :[ @ dup 2dup colours emit normal . ]; swap iterate ;
: all  ( list -- list node n node n...)                | return all nodes and data in list
        temp off
        dup dup @                                      | start with top node
        :[ dup @ @                                     | fetch data
           swap get-node                               | go back one and fetch node address
           temp ++ true ];                             | keep a count of the # of nodes for sort
         rot iterate drop ;
: sort ( node n node n... -- node-max n-max...node-min n-min)
        temp @ 0do
           remains 0do                                 | pass through data
              0 pick 3 pick <if                        | leaving largest on stack
                 >x >x                                 | while moving
              else                                     | all lesser
                 rot >x rot >x                         | to aux stack
              then
           loop
           remains 0do                                 | now output all
              x> x>                                    | lesser
           loop
        loop ;                                         | for the next pass
: relink ( list node-max n-max...node-min n-min --)
        drop 0 over !
        temp @ 1 ?do
           2 pick !
           drop
        loop
        swap ! ;
: center ( u -- )
        X over - 2/ abs 1- Y gotoxy space ;
: clear-line ( n --)                                    | clear n+1 lines on the screen
        0do  0 Y i + gotoxy X normal spaces  loop ;
: msg) ( n --)                                         | place cursor n lines below the map
        0 Y rot + gotoxy ;
: msg ( a u --)                                        | center string just below the map and print
        center type space ;
   variable bench)
: bench ( xt --)
        ms@ bench) !  execute  ms@ bench) @ -  cr ." Generated in: " . ." ms" cr ;  | benchmark
: .ascii
        7 1 do  i emit  i 3 .r  loop
        11 emit 11 4 .r 12 emit 12 4 .r
        255 14 do  i 13 mod 0if  cr  then  i emit space i 3 .r  loop ;

| •••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
|                             ££   £  £££ £££   £££ £££ £££ £    ££
|                            £ _  £-£ £|£ £-     £  £ £ £ £ £    £
|                             ££  £ £ £ £ £££    £  £££ £££ £££ ££
|                             ••••••••••••••••••••••••••••••••••••
|                                        
|                                       
|                                        
|                                       
| record plotting information
   2variable tracks                                    | important, records x y position for
: tracks! ( x y --)  tracks 2! ;                       | terrain generator
: tracks@ ( -- x y)  tracks 2@ ;
: 0tracks ( --)  0 0 tracks! ;

: (map)  parsews >single 0; drop 2, (map) ;
: map[ ( <bytes> <]> --)                               | inline data of 2-bytes max 
        16 base xchg  (map)  2drop base ! ;

   0 constant hidden  1 constant terrain  2 constant item  3 constant ground  4 constant above
: >layer ( a n | x y z n -- a')                        | no matter if input is a ptr or 3-D coord,
        swap dup Z >if  a>xyz  then  drop rot xyz>a ;  | convert to specified map layer
: >above    above   >layer ;
: >ground   ground  >layer ;
: >item     item    >layer ;
: >terrain  terrain >layer ;
: >hidden   hidden  >layer ;

: race  2+ ;    : xyz  4 + ;       : energy  7 + ;     | offsets into actor array
: turns  8 + ;  : leagues  12 + ;  : traveler  16 + ;  : init  17 + ;  : skill  18 + ;

: xyz! ( x y z a-me --)                                | store current x y z
        xyz >r -rot swap r@ c!  r@ 1+ c!  r> 2+ c! ;
: location ( a-me -- x y z)                            | fetch current x y z
        xyz dup >r c@  r@ 1+ c@  r> 2+ c@ ;
: -energy ( a-me --)                                   | decrement energy by movement
        energy dup c@ 6 - swap c! ;
: !energy ( a-me --)                                   | restore energy
        energy 10 swap c! ;
: +turns ( a-me --)                                    | increment turns by 1
        turns ++ ;
: +leagues ( a-me --)                                  | increment leagues by 1
        leagues ++ ;

: .xyz ( x y z --)
        0 msg)
        rot black bold ." x" magenta .#
        swap black bold ." ," ." y" magenta .#
        black bold ." ," ." z" magenta .#
        normal ;
: .turns
        black bold ." turns:" me turns @ magenta . normal ;
: .leagues
        black bold ." leagues:" me leagues @ magenta . ;
: .info
        0 msg) .xyz .turns .leagues ;

| •••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
|                                          ££  ££   ££
|                                          £_£ £ £ £ _
|                                          £ \ £ £  ££
| based on a Charles Childers' port        •••••••••••
| of a George Marsaglia listing
~priv
   916191069 variable, w   123456789 variable, x
   362436069 variable, y   521288629 variable, z
: ishft ( n n -- ishft)  dup if dup 0 >if << else negate >> then then ;
: m ( n n -- m)  over swap ishft xor ;
: rx  x @ 69069 * 1327217885 + dup x ! ;
: ry  y @ 13 m -17 m 5 m dup y ! ;
: rz  z @ dup 65535 and 18000 * swap -16 ishft + dup z ! ;
: rw  w @ dup 65535 and 30903 * swap -16 ishft + dup w ! ;
: kiss  rz 16 ishft rw + rx + ry + ;
: seed  ms@ dup 2dup w +! x +! y +! z +! ;
: rand  ( max -- n<max)  kiss swap mod abs ;
to~ ~caravan seed
to~ ~caravan rand
exit~

seed                                                   | seed the RNG.

| •••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
|                                 ££ ££   £  £££ £ £ £££  ££  ££
|                                £ _ £_£ £_£ £_£ £££  £  £    £
|                                 ££ £ \ £ £ £   £ £ £££  ££ ££
|                                 •••••••••••••••••••••••••••••
| colours
: cherry                     red bold ;
: azure                      blue bold ;
: aqua                       cyan bold ;
: lime                       green bold ;
: grey                       black bold ;
: pearl                      white bold ;
: lemon                      yellow bold ;
: pink                       magenta bold ;
: onbCyan                    onCyan brightBg ;
: onbBlue                    onBlue brightBg ;
: onGrey                     onBlack brightBg ;
: onbYellow                  onYellow brightBg ;
: onbWhite                   onWhite brightBg ;
: sandy                      yellow onbYellow ;
: 2cyan         2 rand  0if  cyan  ;then  aqua ;
: 2green        2 rand  0if  green  ;then  lime ;
: 2grey         2 rand  0if  white  ;then  grey ;
: 2red          2 rand  0if  red  ;then  cherry ;
: greengrey    14 rand  0if  grey  ;then  green ;
: 2white        2 rand  0if  white  ;then  pearl ;
: 2yellow       2 rand  0if  yellow  ;then  lemon ;
: yellowgreen   2 rand  0if  yellow  ;then  green ;
: g-yellow     14 rand  0if  green  ;then  2yellow ;
: y-green      14 rand  0if  yellow  ;then  2green ;
: onSnow        3 rand  0if  onbWhite  ;then  onWhite ;
: checkered     temp @  0if  white temp on ;then temp off ;
: 2blue         2 rand  0if  azure onBlue  ;then  blue onbBlue ;
: blanc         3 rand  0if  pearl onWhite  ;then  white onbWhite ;
: snowy         3 rand  0if  grey onbWhite  ;then  white onbWhite ;
: tan           3 rand  0if  lemon onYellow  ;then  yellow onbYellow ;
: 3grey         5 rand  dup 0if  drop pearl  ;then  1if  white  ;then  grey ;
: greenblue     8 rand  dup 5 <if  drop green  ;then  5 >if  blue  ;then  black ;
: 2greengrey    5 rand  dup 0if  drop 2grey  ;then  1 3 >< if  green  ;then  lime ;
: onIce         3 rand  dup 0if  drop onWhite  ;then  1if  onbWhite  ;then  onCyan ;
: 2yellowgrey   5 rand  dup 0if  drop 2grey  ;then  1 3 >< if  yellow  ;then  lemon ;
: greenGblue    8 rand  onGreen dup 0if  drop cyan  ;then  5 >if  yellow  ;then  green ;
: cyanblanc     3 rand  dup 0if  drop white  else  1if  pearl  else  cyan  then then  onIce ;
: tropical     20 rand  dup 0if red else dup 1if  magenta  else  dup 2 3 >< if lemon else
                        dup 4 9 >< if  lime  else  green  then then then then  drop ;
: rainbow      14 rand  dup 6 <if  green  else  dup 6 =if  aqua  else  dup 7  =if  red  else
                        dup 8 =if  magenta  else  dup 9  =if  pearl  else  yellow
                        then then then then then  drop 2 rand 0if  bold  then ;

| outworld terrain
   : bleaf '% ;    : conifer '& ;  : desert 21 ;  : fen 34 ;      : hill 350 ;  : hill2 606 ;
   : jungle 293 ;  : mount '^ ;    : ocean 176 ;  : grassl 247 ;  : ice 2780 ;  : river 3036 ;
   : steppe 503 ;
   : bleaf)   ['] bleaf  ['] cave-alg ;   : conifer)  ['] conifer ['] north-alg ;
   : desert)  ['] desert ['] south-alg ;  : fen)      ['] fen     ['] cave-alg ;
   : grassl)  ['] grassl ['] cave-alg ;   : hill)     ['] hill    ['] cave-alg ;
   : hill2)   ['] hill2  ['] cave-alg ;   : ice)      ['] ice     ['] polar-alg ;
   : jungle)  ['] jungle ['] south-alg ;  : mount)    ['] mount   ['] cave-alg ;
   : river)       river  ['] river-alg ;  : steppe)   ['] steppe  ['] cave-alg ;

| inworld terrain
   : bridge 240 ;  : flower 802 ;  : gold 206 ;  : grass 290 ;  : pine 294 ;   : prairie 546 ;
   : road 246 ;    : rock 862 ;    : sand 432 ;  : snow 688 ;   : swamp 231 ;  : water 220 ;
   : grass)   ['] grass  ['] cave-alg ;   : prairie)  ['] prairie ['] cave-alg ;
   : pine)    ['] pine   ['] cave-alg ;   : lake)     ['] water   ['] cave-alg ;
   : road)        road   ['] road-alg ;   : rock)     ['] rock    ['] cave-alg ;
   : sand)    ['] sand   ['] cave-alg ;   : snow)     ['] snow    ['] cave-alg ;
   : swamp)   ['] swamp  ['] cave-alg ;

| building materials
   : brick 178 ;  : citywall 547 ;  : fence 197 ;    : tile 249 ;      : stone 291 ;   : door/ '/ ;
   : door+ '+ ;   : door++ 299 ;    : door+++ 555 ;  : door++++ 811 ;  : window/ '| ;  : window+ 380 ;
: door  5 rand 0if door/ ;then  4 rand 256 * door+ + ; | open or closed, if closed unlocked or locked
: window  5 rand 0if window/ ;then window+ ;
: straw  9 rand dup 0if drop flower ;then 1 4 >< if prairie ;then grass ;
: brickhouse  8 rand 4 + to wide  8 rand 4 + to long  ['] tile ['] brick ['] room-alg ;
: stonehouse  8 rand 4 + to wide  8 rand 4 + to long  ['] tile ['] stone ['] room-alg ;
: pen         9 rand 5 + to wide  9 rand 5 + to long  ['] straw ['] fence ['] room-alg ;
| ... orchard, vineyard...

| occupations
    133 constant archer       134 constant cavalry      168 constant corpse       570 constant foot
     '@ constant hero          'h constant highwayman   143 constant knight        'm constant merchant  
      7 constant actor        131 constant scout        160 constant slinger      132 constant spearman
    142 constant swordsman
| races
   1000 constant Petcheneg   1001 constant Varangian   1002 constant Celt        1003 constant German
   1004 constant Frank       1005 constant Magyar      1006 constant Jew         1007 constant Turk
   1008 constant Hindu       1009 constant Persian     1010 constant Byzantine   1011 constant Moor
   1012 constant Arab        1013 constant Slav
| misc
    235 constant bomb          15 constant snowflake     46 constant blood1       505 constant blood2 
: blood  red 2 rand 0if blood1 ;then blood2 ;

: traveler? ( c -- t)
        dup >r merchant =  highwayman r@ = or  scout r@ = or  spearman r@ = or
        archer r@ = or  cavalry r@ = or  swordsman r@ = or  knight r@ = or  slinger r> = or ;

: ?terrain1
        case
           0 of bleaf) endof     1 of conifer) endof   2 of desert) endof
           3 of river) endof     4 of fen) endof       5 of hill) endof
           6 of hill2) endof     7 of jungle) endof    8 of mount) endof
           9 of steppe) endof   10 of grassl) endof
           drop
        endcase ;

: ?terrain2
        case
           0 of bleaf) endof     1 of grass) endof     2 of jungle) endof
           3 of pine) endof      4 of prairie) endof   5 of rock) endof
           6 of swamp) endof
           drop
        endcase ;

:: ( c --)
        case
           brick of 2grey endof       bridge of white endof       bleaf of 2green endof
           blood1 of red endof        blood2 of red endof         conifer of green endof
           corpse of red endof        desert of 2yellow endof     door+ of yellow endof
           door/ of yellow endof      fen of greenblue endof      fence of white endof
           tile of grey endof         flower of tropical endof    gold of 2yellow endof
           grass of 2green endof      grassl of y-green endof     hero of magenta endof
           hill of 2greengrey endof   hill2 of 2yellowgrey endof  ice of cyanblanc endof
           jungle of tropical endof   mount of 2white endof       ocean of blue endof
           pine of greengrey endof    prairie of 2yellow endof    river of blue endof
           road of grey endof         rock of white endof         sand of tan endof
           snow of blanc endof        steppe of g-yellow endof    stone of 2grey endof
           swamp of greenGblue endof  water of 2blue endof        window+ of grey endof
           window/ of white endof
           Petcheneg of grey endof    Varangian of blue endof     Celt of aqua endof
           German of green endof      Frank of lime endof         Magyar of azure endof
           Jew of cyan endof          Turk of red endof           Hindu of cherry endof
           Persian of magenta endof   Byzantine of pink endof     Moor of yellow endof
           Arab of lemon endof        Slav of pearl endof
           drop grey
        endcase ;
is colours

: Bgcolours
        case
           ice of onIce endof     river of onBlue endof    sand of onbYellow endof
           snow of onSnow endof   swamp of onGreen endof   water of onBlue endof
           drop
        endcase ;

: npc? ( c -- t)                                       | 79 unique occupations
        dup >r 65 90 ><  r@ 97 122 >< or  r@ 128 144 >< or  r@ 147 154 >< or  r> 159 165 >< or ;

: animal? ( c -- t)
        drop false ;

: filter ( c -- c-root | c )
        dup 256 mod >r ( c)                            | if the glyph is a multiple
        r@ 220 = ( c t)                                | of water
        r@ hero = or ( c t)                            | or hero,
        r> npc? or ( c t)                              | or an npc,
        over ice < ( c t t)                            | and it's not ice
        and if  256 mod  then ;                        | return the root 

: actor? ( c -- t)
        filter dup >r hero =  r@ npc? or  r> animal? or ;

: fetch ( c list -- a-me)
        :[ @ over over w@ =if nip false ;then drop true ]; swap iterate ;

: colour ( a --)
        dup w@ actor? if ( a)                          | is it hero/npc/animal? if so
           dup >terrain w@ ( a c-terrain)              | fetch that square's terrain
           filter Bgcolours ( a)                       | and colour the background.
           w@ census fetch race ( a-race)              | get the npc's race, or if hero, state
        then
        w@ filter colours ;                            | else/then colour the foreground

: etch ( xt-c a --)
        >r execute r> w! ;                             | store c to the map

: .square ( a --)
        dup a>xyz drop gotoxy                          | go to screen position,
        dup colour w@ emit                             | colour then print.
        normal ;                                       | restore to default colour

| •••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
|                                        £££ £££ ££  £ £
|                                        £|£ £-  £ £ £ £
|                                        £ £ £££ £ £ £££
|                                        •••••••••••••••

: .border ( --)
        yellow
        X 0do  i Y gotoxy  196 emit  loop
        0 Y gotoxy 214 emit  X Y gotoxy 183 emit 
        0 Y 1+ gotoxy 186 emit  X Y 1+ gotoxy 186 emit
        0 Y 2+ gotoxy 186 emit  X Y 2+ gotoxy 186 emit ;
: .instruct ( --)
        1 msg)
        6 spaces cherry ." numpad" yellow ." ," cherry ." iopkl;,./ " yellow ." - move around"
        3 spaces cherry ." u" yellow ." se - manipulate doors and windows" cr
        X 0do  i Y 2+ gotoxy  196 emit  loop
        30 Y 2+ gotoxy cherry ."  Q" yellow ." uit - leave game " ;

: .menu ( --)
        .border .instruct ;
: border ( c --)
        X 0do dup emit loop drop ;

| •••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
|                                   £   ££ £££  £  £££ ££   ££
|                                  £_£ £    £   £  £ £ £ £  £
|                                  £ £  ££  £   £  £££ £ £ ££
|                                  ••••••••••••••••••••••••••

   create player
        here temp !
        hero 2,
        Celt 2,                                        | status
        0 1, 0 1, above 1,                             | xyz
        10 1,                                          | energy
        0 , 0 ,                                        | turns, leagues
        true 1,                                        | traveler
        20 1,                                          | initiative
        50 1,                                          | skill
        temp @ census link

: ?msg ( a u --)
        me player =if  pearl msg  ;then  2drop ;       | only print message if we're the player
: roll ( stat -- n)
        c@ rand ;

: N  X Z * cells - ; : NE  X Z * Z - cells - ; ( a -- a')
: E    Z   cells + ; : SE  X Z * Z + cells + ;         | modify a to simulate movement on the array
: S  X Z * cells + ; : SW  X Z * Z - cells + ;
: W    Z   cells - ; : NW  X Z * Z + cells - ;

| acts
: N)  dup N  0 -1 ;  : NE)  dup NE  1 -1 ; ( a -- a a'x+ y+)
: E)  dup E  1  0 ;  : SE)  dup SE  1  1 ;             | dup and x+ y+ is for bounds check
: S)  dup S  0  1 ;  : SW)  dup SW -1  1 ;
: W)  dup W -1  0 ;  : NW)  dup NW -1 -1 ;
: err  .border " Eh?" msg ;
: Quit
        " Retire? (y/n)" lemon msg  ekey 'y =if
           " Farewell..." msg .stack 2000 ms cls bye
       ;then  .border ;

: bump ( a' c --)
        2drop ;

: shut ( a-xyz a-layer --)
        nip " The door shuts." ?msg
        dup door+ swap w! .square ;
: lock ( a-xyz a-layer --)
        nip " It's now locked." ?msg
        dup door++ swap w! .square ;
: ?unlock ( a-xyz a-layer --)
        dup w@ ( a-xyz a-layer c)
        case
           door++ of door/ 10 endof     door+++ of door/ 20 endof
           door++++ of door/ 49 endof   window+ of window/ 10 endof
           drop
        endcase
        ( a-layer a-me c' n)
        me skill roll <if ( a-xyz a-layer c')
           over w! .square
           " Deftly freed." ?msg
           drop
       ;then
        " Won't budge." ?msg  3drop ;

: ?direction ( a-xyz k --)
        case
           33 of NE endof   34 of SE endof   35 of SW endof   36 of NW endof
           37 of W endof    38 of N endof    39 of E endof    40 of S endof
           'p of NE endof   '/ of SE endof   ', of SW endof   'i of NW endof
           'k of W endof    'o of N endof    '; of E endof    '. of S endof
           drop err
        endcase ;

   door/ usables link     door+ usables link    door++ usables link  door+++ usables link
   door++++ usables link  window+ usables link  window/ usables link

: use) ( a-xyz a-layer c-layer --)
        case
           door/ of shut endof        door+ of lock endof         door++ of ?unlock endof
           door+++ of ?unlock endof   door++++ of ?unlock endof   window+ of ?unlock endof
           window/ of lock endof
           drop
        endcase ;

: ?usable ( a-xyz --)
        Z 0do                                          | for every layer in that square
           dup remains 1- >layer dup w@ filter ( a-xyz a-layer c-layer)
           dup usables in-list? if  use) unloop  ;then      | find any usable objects
           2drop
        loop  drop " He clutches at the air." ?msg ;   | else give the fool's message

: use ( --)
        me location xyz>a ( a-xyz)
        " Where?" ?msg                                 | computer is dumb, so player
        ekey ?direction 0;                            | must specify where he wants to use
        ?usable ;

: move-key? ( k -- t)
        dup >r 0 7 ><  r@ 33 40 >< or  r@ ', = or  r@ '. '/ >< or
        r@ '; = or  r@ 'i = or  r@ 'k = or  r> 'o 'p >< or ;
: valid-key? ( k -- t)
        dup >r move-key? r@ 12 = or  r@ 'l = or  r@ 'Q = or  r> 'u = or ;

: wipe ( a-me --)
        location xyz>a dup ( a-xyz a-xyz)              | get previous location (now vacated square)
        >r >above dup w@ me w@ =if
           0 swap w! ( --)                             | clear actor's glyph from layer
        else
           drop
        then
        foot r@ >hidden w! ( --)                       | footprints on ground for future use
        r@ >terrain dup w@ dup ( a-terr c c)           | fetch that square's terrain
        sand =if  2drop sandy foot  else               | is it sand? prepare sandy footprint
        snow =if   drop snowy foot  else ( a-terr)     | is it snow? prepare snowy footprint
        r@ >item dup w@ if ( a-terr a-item)            | else, anything in the item layer,
           nip else  drop r@ >above dup w@ if          | or above? if so,
              nip else  drop                           | prepare it, else prepare terrain
        then then ( a-terr | a-item | a-above)
           dup colour w@ ( c)                          | colour it
        then then                                      | and
        r> a>xyz drop gotoxy emit normal ;             | print to screen

: move-ok ( a'--)
        me dup >r w@ over w! ( a')                     | store actor glyph to map square
        dup .square ( a')                              | print to screen
        r@ wipe ( a')                                  | reprint contents of last location
        a>xyz r@ xyz! ( --)                            | store current location
        r@ +leagues r> -energy ;                       | incr turns and leagues, decr energy

: ?boat ( a'c --)
        2drop " The sea waves." ?msg ;

: ?climb ( a'c --)
        2 rand 0if
          drop move-ok
          " He clambers over." ?msg  250 ms
          keypress act
       ;then  2drop " It's too high!" ?msg ;

: say-x ( u -- x)
        dup 2/
        me location 2drop
        swap - 0 max X rot - min ;
: say-y ( -- y)
        me location drop nip dup 3 >if 1- ;then 1+ ;
: .say ( a u --)
        dup say-x say-y 3dup >x >x >x 0 >x gotoxy me race colour type ;
: ?say-wipe
        x> 0if
           x> x> x> 2dup 0 xyz>a >r ( u x y)
           swap rot + swap Z xyz>a r> do
              i w@ if  i .square  then
              1 cells 1- skip
           loop
        then ;

: ?combat ( a'c --)
        dup traveler? if
           census fetch skill roll  me skill roll <if ( a')
              blood swap >item w!
              " The foe is vanquished." ?msg
          ;then
           drop
           blood me location xyz>a >item w!
           " Beaten..." ?msg
       ;then
        2drop " \"Sorry\"" .say ;
| Conversations eat up turns, as to advance dialog one must press 'stay' key.
| Indicate speaker has more to say with > symbol.

: locked ( a' c --)
        2drop " Seems to be locked." ?msg ;

: open ( a' c --)
        drop >terrain door/ over w! .square ;

: ?swim ( a' c --)
        2drop " He seems unsure of the water." ?msg ;

   ocean events link     brick events link    stone events link   window/ events link
   fence events link     door+ events link    door++ events link  door+++ events link
   door++++ events link  window+ events link  river events link   water events link
   actor events link

: event) ( a' c c --)
        case
           ocean of ?boat endof       brick of bump endof       stone of bump endof
           window/ of ?climb endof    fence of ?climb endof     door+ of open endof
           door++ of locked endof     door+++ of locked endof   door++++ of locked endof
           window+ of locked endof    river of ?swim endof      water of ?swim endof
           actor of ?combat endof
           drop
        endcase ;

: ?event ( a' --)
        Z 0do
           dup remains >layer w@ filter ( a'c)         | check all the square's layers
           dup actor? if  drop actor  then             | (actors converted to universal ID)
           dup events in-list? if
              dup event) unloop                        | trigger any events
          ;then drop
        loop  move-ok ;                                | otherwise move there

: outbounds? ( x y -- t)
        over 0 <  >r                                   | did we pass the left edge?
        dup  0 <  >r ( x y)                            | top?
        Y = >r                                         | right edge?
        X =                                            | or bottom?
        r> r> r> or or or ;

: inbounds? ( a a'x+ y+ -- a't)
        >r rot a>xyz drop r> + >r + r>                 | add proposed x+ y+ to current xyz
        outbounds? not ;                               | test, return opposite truth val

: move ( xt-direction --)
        me location xyz>a                              | fetch actor's current location
        swap execute                                   | process directional move
        inbounds? if ?event ;then                      | if still inbounds, check for events in that square
        me player =if drop in-map? off ;then           | else we passed edge, so if hero, exit
        drop ;                                         | else we're an npc so stop at the edge

:: ( k --)
        dup to keypress
        case
            0 of ['] N) move endof     1 of ['] NE) move endof    2 of ['] E) move endof
            3 of ['] SE) move endof    4 of ['] S) move endof     5 of ['] SW) move endof
            6 of ['] W) move endof     7 of ['] NW) move endof
           33 of ['] NE) move endof   34 of ['] SE) move endof   35 of ['] SW) move endof
           36 of ['] NW) move endof   37 of ['] W) move endof    38 of ['] N) move endof
           39 of ['] E) move endof    40 of ['] S) move endof    12 of noop endof
           'p of ['] NE) move endof   '/ of ['] SE) move endof   ', of ['] SW) move endof
           'i of ['] NW) move endof   'k of ['] W) move endof    'o of ['] N) move endof
           '; of ['] E) move endof    '. of ['] S) move endof    'l of noop endof
           'Q of Quit endof           'u of use endof
           drop err
        endcase ;
is act

| •••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
|                                        ££  ££   £  £ £ 
|                                        £ £ £_£ £_£ £|£
|                                        ££  £ \ £ £ £££
|                                        •••••••••••••••

: advance ( a-xyz k --)
        dup to keypress
        case
            0 of N) endof     1 of NE) endof    2 of E) endof     3 of SE) endof
            4 of S) endof     5 of SW) endof    6 of W) endof     7 of NW) endof
            drop err
        endcase ;

: advance-terrain ( c a n -- c a't | t)
        advance ( c a a'x+ y+)                         | advance to next square
        inbounds? if ( c a')                           | are we still inside the map?
           dup a>xyz drop tracks! true ( c a't)        | if so, update tracks and exit, continuing loop
       ;then  2drop false ;                            | else drop everything and stop loop


: .test  dup .square ;

:: ( xt-c --)
        3 rand 0if                                     | roll random starting x y, 
           X rand Y rand                               | either purely random
        else                                           | or
           X rand 0                                    | somewhere at top of map
        then
        2dup tracks! terrain xyz>a                     | get a
        repeat
           2dup etch                                   | etch c to map
           | .test
           tracks@ nip
           Y 8 / <if  6 rand 2+  else  8 rand  then    | > 1/8 from top? E SE S SW W NW, else any
           advance-terrain
        while ;
is cave-alg

:: ( xt-c --)
        X rand  Y dup rand ( xt-c x' Y y')
        swap 2/ min
        2dup tracks! terrain xyz>a ( xt-c a)
        repeat
           2dup etch
           | .test
           tracks@ nip dup ( xt-c a y y)
           Y 7 / <if  drop 6 rand 1+  else             | < 1/7 from top? NE E SE S SW W
           Y 2/  >if  4 rand  else  8 rand             | > 1/2 from top? N NE E SE, else any
           then then
           advance-terrain
        while ;
is north-alg

:: ( xt-c --)
        0 0 2dup tracks! terrain xyz>a ( xt-c a)
        repeat
           2dup etch ( xt-c a)
           | .test
           tracks@ ( xt-c a x y)
           dup 0if                                     | top?
              2drop 3 rand 2+                          | E SE S
           else  drop 0if                              | left edge?
              3 rand                                   | N NE E
           else  4 rand 0if                            | otherwise roll a d3. if 0,
              2 rand 4 +                               | S SW
           else                                        | else,
              2 rand                                   | N NE
           then then then
           advance-terrain
        while ;
is polar-alg

: outworld? ( -- t)
        Y 1- 0do
           0 i terrain xyz>a w@ ocean =if
              unloop true
           ;then
        loop false ;

: ?thicken ( xt-c a --)
        outworld?  tracks@ >r X 1- = r> Y 1- = or
        or 0if                                         | if not in outworld or at map edge,
           S w!                                        | draw the same terrain south
        ;then 2drop ;

: (meander) ( n --)
        3 rand 0do dup >x dup >x  loop drop ;
make meander ( -- n)
        7 2 do  i (meander)  loop  7 2 do  remains 1+ (meander)  loop  x@ ;
make meander? ( n -- t)
        dup 0 = ;

:: ( c --)
        outworld? 2 rand or if                         | in the outworld, or rolled 1?
           X rand
        else
           0
        then                                           | choose a purely random start square
        Y rand                                         | otherwise start at the left edge
        2dup tracks! terrain xyz>a ( c a)
        repeat
           dup w@ >r ( c a)                            | get current square
           r@ ocean = r@ river = or                    | ocean, river,
           r@ filter water = r> thiswater <> and
           or if                                       | or a different stream or lake?
              2drop                                    | if so,
           ;then ( c a)                                | quit blazing
           2dup w!                                     | else draw
           | .test
           2dup ?thicken                               | double-sized if we're inworld
           200 rand meander? if                        | roll. if there's meandering to do,
              drop meander
              ['] x> >defer meander
              :[ x@ 7 < ]; >defer meander?
           else  1 25 >< if
              4 rand 2+                                | E SE S SW, 
           else
              4 rand                                   | or mostly N NE E SE
           then then
           advance-terrain
        while
        undo meander  undo meander? ;
is river-alg

: buildbridge ( a --)
        bridge over w!
        | .test
        keypress advance-terrain ;                               | draw across last given direction

: ?bridge ( xt-c a c-terrain c-water -- c a)
        =if                                            | if it's water,
           repeat
              buildbridge 00; drop                    | build a bridge square
              dup w@ filter water =                    | as many times as there are water squares
           while
           buildbridge 00; drop                       | plus one for good measure
           bridge over w!
           | .test
        else                                           | otherwise,
           2dup w!                                     | draw a road
           | .test
        then
        2dup ?thicken ;                                | double-sized if we're inworld

:: ( xt-c --)
        4 rand dup >x 3 =if                            | prepare direction offset, is it 3? if so,
           X 1- Y rand                                 | start somewhere at the right edge
        else                                           | otherwise
           0 Y rand                                    | somewhere at the left edge
        then
        2dup tracks! terrain xyz>a ( xt-c a)
        repeat
           dup w@ dup ( xt-c a c c)                    | get current square
           ocean =if                                   | is it an ocean? if so, 
              3drop                                    | quit blazing.
           ;then
           filter water ?bridge 0;                    | water? build bridge, else build road
           3 rand x@ dup 1if
              2 rand 0if
                 +
              else
                 2drop keypress
              then                                     | roll an overriding set of directions
           else
              dup 3 =if
                 nip 4 rand 1+ +
              else
                 +
              then
           then
           advance-terrain
        while ;
is road-alg

:: ( xt-c -- )
        8 rand 2+ 0do                                  | how many things do you want to scatter?
           X rand  Y rand 2dup tracks! terrain xyz>a ( xt-c a)
           over swap etch
           | .test
        loop  drop ;
is scatter-alg

:: ( xt-c --)
        0 Y 1- 2dup tracks! terrain xyz>a ( xt-c a)
        repeat
           2dup etch
           | .test
           2dup 3 rand  3 rand dup 0if
              drop 2+
           else 1if
              4 +
           then then
           0 ?do
              N 2dup etch
           loop
           2drop  2 advance-terrain
        while ;
is shave-alg

:: ( xt-c --)
        X rand  Y dup rand ( c x' Y y')
        swap dup 3 / - max
        2dup tracks! terrain xyz>a ( c a)
        repeat
           2dup etch
           | .test
           tracks@ nip ( c a y)
           Y dup 3 / - <if
              5 rand 1+                                | more than 1/3 from bottom? NE E SE S SW,
           else
              8 rand                                   | else, any direction
           then
           advance-terrain
        while ;
is south-alg

: getmaterial ( xt-c xt-dir a1 a2 -- xt-c xt-dir a1 a2 c)
        dup w@ >r                                      | is the current square
        brick r@ =  stone r> = or if                   | a wall?
           15 rand                                     | if so
           dup 0if  drop door  ;then                   | prepare a door, 
               1 2 >< if  tile  ;then                  | a floor tile
              wall                                     | or most likely a wall
       ;then                                           | otherwise,
        3 pick execute ;                               | prepare whatever's at the xt (c-wall or c-tile)

: measure ( a1 -- a1 x'y')
        dup a>xyz drop >r wide + r> long + ;

: outabounds? ( x'y' -- t)
        Y 2- > >r                                      | at the right edge?
        X 2- > r> or ;                                 | or bottom?

: .test2 ( a --)  dup a>xyz drop gotoxy 1 emit 50 ms ;

: obstacle? ( a1 x'y'a1-- t)
        long 0do                                       | for the length and
           wide 0do                                    | width of the building
              | .test2
              dup w@ >r ( a1)
              r@ citywall =                            | check for obstacles
              r@ road = or
              r@ bridge = or
              r@ swamp = or
              r> filter water = or ( a1 t)
              if
                 drop true unloop unloop
             ;then
              E
           loop  drop
           2 pick i 1+ 0do
              S
             | .test2
           loop
        loop  drop false ;

: impossible? ( -- t)
        temp ++ temp @ dup 40 =if
           drop true
       ;then
        20 =if
           -1 +to long  -1 +to wide
        then  false ;

: ?retry ( a1 x'y't -- t)
        if  3drop impossible?                          | check if we ain't beating a dead horse
           if  2drop false  ;then
           room-alg false                              | before trying another start square
       ;then ;

: build ( xt-c xt-dir a1 a2 n -- c a1 a2)
        1 do ( ...xt-dir a1 a2)
           dup w@ tile =if ( ...xt-dir a1 a2)          | check the square, is it a floor tile? if so,
              2 pick execute                           | skip to next square,
              remains 1+
              dup 1if                                  | unless we've already gone the length of the wall.
                 drop leave
              then
              unloop build
          ;then
           getmaterial                                 | choose a building material
           dup wall =if                                | if it's a wall,
              over >x                                  | remember address for future door-drawing
           then
           over ( xt-c xt-dir a1 a2 c a2) w!           | draw it
           | .test 2 ms
           2 pick execute ( ...xt-dir a1 a2')          | advance in specified direction
        loop  rot drop ;                               | drop direction

: walls ( xt-tile xt-wall a1 a2 -- xt-tile xt-wall a1 a2)
        ['] N -rot long build      ( ...a1 a2)         | 'long' is the limit for drawing N-S walls
        ['] W -rot wide build swap ( ...a2 a1)         | 'wide' for E-W walls
        ['] S -rot long build      ( ...a2 a1)
        ['] E -rot wide build swap ( xt-ctile xt-cwall a1 a2)
        rot drop ;                                     | drop wall glyph

: put) ( xt-door|window --)
        x dup stack-size rand ( xt-c stack n)          | choose a random wall in aux stack
        swap peek-n >r execute r> w! ;                 | and replace it with a door or window

: doors ( --)
        4 rand 0do                                     | put 1 to 3 doors somewhere on the building
           ['] door put)
        loop ;

: windows
        3 rand 0 ?do                                   | 0 to 2 windows
           ['] window put)
        loop ;

: floor ( xt-tile a1 a2 -- a2 xt-tile a1)
        SE -rot NW ( a2 xt-f a1)                       | move inside the walls.
        wide 1- 1 do ( a2 xt-f a1)                     | for the width of the building less 1,
           2 pick i 1 ?do  E  loop ( a2 xt-f a1 a2')   | and moving one square east each iteration,
           ['] S -rot long 1- build drop ( a2 xt-t a1) | lay floor tile the building's length less 1.
        loop ;

:: ( xt-ctile xt-cwall --)
        dup execute to wall                            | store the type of wall we're using
        X 1- rand 1+  Y 1- rand 1+ ( xt-cf xt-cw x y)  | get random start square away from the edge
        | 2dup gotoxy red bold 177 emit 200 ms normal
        terrain xyz>a ( ...a1)                         | calculate corresponding address in array
        measure ( ...a1 x'y')                          | add wide and long to x y
        2dup outabounds? ?retry 0;                    | if outside the map, start over
        2 pick obstacle? ?retry 0; ( ...a1 x'y')      | if on an obstacle, start over
        terrain xyz>a NW ( ...a1 a2)                   | otherwise calculate address
        walls doors windows floor                      | build it
        3drop  xreset ;                                | clean up
is room-alg

| •••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
|                                          £££  £  £££
|                                          £|£ £_£ £_£
|                                          £ £ £ £ £
|                                          ••••••••••

   create europe
      map[ b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 15e b0 b0 b0 b0 b0 
           b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 
           b0 b0 26 26 26 26 5e 26 26 bdc 26 26 26 26 26 26 26 26 26 26 26 26 26 b0 b0 b0 b0 b0 
           b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 
           b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 26 26 26 26 
           26 26 5e bdc 26 26 26 26 26 26 26 26 26 26 26 26 bdc bdc b0 b0 b0 b0 b0 b0 b0 b0 b0 
           15e 15e 15e 15e b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 
           b0 b0 15e 26 26 26 26 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 26 b0 26 bdc 26 26 26 26 26 26 
           5e bdc bdc 26 26 26 26 26 26 26 26 bdc bdc bdc 26 26 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 
           15e 15e 15e 5e 15e 15e b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 
           15e 5e 5e 26 26 15e 26 26 26 26 b0 b0 b0 b0 b0 26 26 b0 26 26 bdc 26 26 26 26 26 26 
           5e 26 26 bdc 26 26 26 26 26 bdc bdc 26 26 26 26 26 b0 b0 b0 b0 b0 b0 b0 b0 b0 15e f7 
           15e 5e 5e 5e 15e b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 15e 15e 5e 26 
           26 26 26 26 26 26 26 26 26 26 26 26 b0 b0 26 26 26 26 bdc 26 bdc bdc 26 26 5e 5e 26 
           26 bdc bdc bdc bdc bdc bdc 26 26 26 26 26 26 26 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 15e f7 
           15e 5e 15e 15e b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 15e 15e 5e 26 26 
           26 26 26 26 26 26 26 26 15e 26 26 26 26 b0 b0 26 26 26 bdc bdc bdc 26 bdc 26 5e 15e 
           26 26 26 26 26 26 26 26 bdc bdc bdc 26 26 26 26 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 
           b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 15e 5e 5e 26 26 26 26 
           26 26 26 26 26 26 26 26 26 26 26 b0 26 bdc 26 26 26 26 26 26 26 bdc bdc 15e 15e 26 
           26 26 26 26 26 26 26 26 bdc 26 26 26 26 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 
           b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 15e 5e 5e 26 26 26 26 26 26 26 26 
           26 26 26 26 b0 b0 b0 b0 26 26 26 bdc bdc bdc bdc 26 26 bdc 26 26 26 26 15e 15e 26 26 
           26 26 26 26 26 bdc 26 26 26 26 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 
           b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 15e 15e 5e 26 26 26 26 26 b0 b0 26 26 26 
           26 26 26 26 b0 26 26 bdc bdc 26 26 26 26 26 26 bdc bdc 26 26 26 bdc bdc 26 15e 15e 
           26 26 26 26 26 b0 bdc 26 26 26 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 
           15e b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 15e 15e 15e 15e 26 26 26 26 26 26 b0 26 26 26 
           f7 26 26 26 26 26 26 26 26 bdc bdc bdc bdc bdc bdc bdc 26 26 26 26 bdc 26 26 bdc bdc 
           26 26 26 26 26 26 26 26 bdc bdc 26 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 
           b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 15e 15e 5e 5e 15e 26 26 26 26 26 b0 b0 f7 26 f7 26 
           26 26 26 26 26 b0 26 26 26 26 26 26 26 26 bdc 26 26 26 26 26 26 bdc 26 26 bdc 26 26 
           26 26 26 26 26 26 26 26 bdc b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 
           b0 b0 b0 b0 b0 b0 b0 15e 5e 5e 5e 15e 26 26 26 26 26 b0 b0 26 26 26 26 f7 26 b0 26 
           26 26 26 26 26 26 26 26 26 bdc bdc 26 26 26 26 bdc bdc bdc bdc 26 26 bdc 26 26 26 26 
           26 26 26 26 26 26 26 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 15e b0 b0 b0 b0 f7 
           b0 b0 b0 b0 15e 5e 5e 5e 15e 26 26 26 26 26 26 b0 b0 b0 26 f7 f7 26 f7 26 26 b0 26 
           26 26 26 26 26 26 bdc 26 26 26 26 26 26 bdc bdc 26 26 26 26 bdc 26 26 26 26 26 26 26 
           26 26 25 26 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 15e f7 f7 b0 b0 b0 b0 b0 
           b0 15e 5e 15e 15e 26 26 26 26 26 26 26 b0 b0 26 b0 b0 b0 b0 b0 b0 26 26 26 bdc bdc 
           26 26 26 b0 26 26 26 26 26 26 26 26 26 bdc bdc 26 bdc bdc bdc bdc 26 bdc bdc 26 26 
           26 25 26 26 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 15e 15e f7 b0 b0 b0 b0 b0 
           b0 b0 15e 15e 26 b0 26 26 26 26 26 f7 26 26 b0 b0 b0 b0 26 26 26 26 26 26 bdc 26 26 
           bdc 26 26 bdc bdc bdc bdc bdc 26 26 26 26 26 26 26 bdc 26 26 26 bdc 26 bdc 26 bdc 26 
           bdc 25 bdc 26 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 15e 15e 15e f7 f7 b0 b0 b0 
           b0 b0 b0 b0 b0 b0 f7 b0 26 b0 26 26 26 26 b0 b0 b0 26 b0 b0 bdc 26 b0 26 26 26 bdc 
           26 26 bdc bdc bdc 26 26 26 25 bdc bdc bdc bdc bdc bdc bdc 25 26 26 26 bdc bdc 26 26 
           26 bdc 25 25 bdc 25 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 f7 f7 f7 b0 f7 15e f7 f7 b0 b0 b0 
           b0 b0 b0 b0 b0 b0 f7 f7 b0 26 26 26 26 26 b0 b0 b0 b0 f7 f7 f7 f7 bdc bdc bdc bdc 
           bdc 26 26 26 26 26 26 26 25 25 bdc 25 25 25 25 26 bdc 25 25 25 26 25 25 26 25 25 26 
           25 25 bdc bdc 25 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 f7 f7 f7 b0 b0 f7 f7 f7 b0 b0 b0 b0 
           b0 b0 b0 b0 b0 f7 f7 f7 b0 26 f7 26 26 b0 b0 b0 f7 f7 f7 f7 f7 f7 f7 f7 f7 f7 f7 bdc 
           26 25 26 25 26 26 bdc 25 f7 25 25 25 25 25 bdc 25 25 f7 25 25 25 25 bdc bdc bdc bdc 
           25 25 25 b0 b0 b0 b0 b0 b0 b0 b0 f7 f7 f7 f7 f7 b0 f7 b0 f7 f7 f7 b0 b0 b0 b0 b0 b0 
           b0 b0 f7 f7 b0 b0 f7 f7 b0 b0 b0 b0 b0 f7 f7 f7 f7 f7 f7 f7 26 f7 bdc bdc f7 f7 bdc 
           f7 bdc bdc bdc 25 25 25 25 25 f7 25 25 bdc f7 25 25 25 25 bdc bdc 25 f7 25 25 25 25 
           25 b0 b0 b0 b0 b0 b0 b0 b0 b0 f7 f7 f7 b0 b0 f7 15e f7 f7 f7 b0 b0 b0 b0 b0 b0 b0 b0 
           f7 f7 f7 f7 b0 b0 b0 26 26 b0 f7 f7 f7 f7 f7 f7 f7 26 f7 bdc f7 f7 26 26 bdc f7 bdc 
           f7 f7 26 f7 f7 f7 25 25 25 bdc 25 25 25 25 f7 bdc f7 f7 f7 f7 f7 25 1f7 25 25 b0 b0 
           b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 f7 15e f7 f7 f7 f7 f7 b0 b0 b0 f7 f7 f7 f7 bdc f7 
           f7 f7 f7 bdc f7 26 f7 bdc f7 f7 f7 f7 f7 f7 f7 f7 f7 bdc f7 f7 f7 f7 bdc f7 f7 f7 
           bdc f7 f7 25 f7 f7 f7 f7 bdc f7 1f7 25 1f7 1f7 1f7 bdc 1f7 1f7 1f7 1f7 1f7 1f7 1f7 
           bdc b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 f7 f7 f7 f7 f7 f7 f7 b0 b0 b0 bdc bdc bdc f7 
           f7 f7 bdc f7 26 26 bdc 26 f7 f7 bdc bdc f7 f7 f7 f7 f7 f7 f7 f7 f7 bdc 26 bdc bdc f7 
           26 f7 f7 f7 bdc f7 1f7 1f7 1f7 1f7 1f7 bdc 1f7 1f7 1f7 1f7 1f7 1f7 bdc 1f7 1f7 1f7 
           1f7 1f7 1f7 bdc 1f7 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 f7 f7 
           f7 f7 f7 bdc bdc f7 f7 f7 bdc f7 f7 f7 bdc f7 f7 f7 f7 bdc f7 f7 f7 f7 f7 f7 f7 f7 
           26 bdc 26 f7 f7 f7 f7 bdc f7 f7 bdc bdc bdc bdc bdc 1f7 bdc 1f7 1f7 1f7 1f7 1f7 1f7 
           1f7 bdc 1f7 1f7 1f7 bdc bdc 1f7 1f7 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 f7 f7 b0 f7 
           f7 f7 f7 f7 f7 f7 f7 bdc bdc f7 bdc f7 f7 15e bdc f7 15e 15e bdc f7 bdc bdc bdc f7 
           f7 f7 f7 f7 f7 26 f7 f7 f7 bdc bdc bdc f7 26 f7 bdc f7 f7 1f7 1f7 1f7 bdc 1f7 1f7 
           bdc bdc 1f7 1f7 1f7 1f7 1f7 bdc 1f7 bdc bdc 1f7 1f7 1f7 1f7 b0 b0 b0 b0 b0 b0 b0 b0 
           b0 b0 b0 b0 f7 f7 f7 f7 f7 f7 f7 f7 f7 f7 bdc f7 f7 f7 bdc 26 26 26 26 bdc f7 f7 f7 
           15e 15e 15e 15e 15e 15e 15e bdc bdc 25 26 f7 f7 f7 f7 f7 f7 bdc f7 f7 26 bdc bdc 1f7 
           1f7 bdc 1f7 1f7 1f7 1f7 1f7 bdc bdc f7 b0 b0 b0 b0 1f7 1f7 1f7 1f7 1f7 1f7 b0 b0 b0 
           b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 bdc bdc bdc bdc bdc bdc f7 f7 bdc f7 f7 bdc f7 bdc 
           bdc 5e 5e 15e bdc bdc bdc bdc 15e 15e 15e bdc bdc 15e 15e 15e bdc bdc bdc f7 1f7 1f7 
           1f7 1f7 1f7 bdc 1f7 1f7 1f7 1f7 bdc bdc 1f7 1f7 1f7 1f7 1f7 1f7 1f7 bdc b0 b0 b0 b0 
           1f7 1f7 1f7 1f7 1f7 1f7 1f7 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 f7 f7 f7 f7 25 
           bdc f7 f7 25 f7 25 5e bdc 15e 5e 5e 5e 5e 15e 26 26 26 bdc f7 bdc f7 f7 bdc bdc 15e 
           15e 25 26 bdc 1f7 1f7 1f7 bdc bdc 1f7 1f7 1f7 1f7 b0 1f7 1f7 1f7 1f7 1f7 1f7 1f7 1f7 
           1f7 1f7 b0 b0 b0 b0 b0 1f7 1f7 1f7 1f7 1f7 1f7 b0 b0 b0 b0 26 f7 f7 b0 b0 b0 b0 b0 
           b0 b0 26 f7 f7 f7 f7 bdc f7 15e bdc bdc 5e bdc 5e 5e 5e 5e 5e 15e 15e 15e 26 f7 bdc 
           f7 bdc f7 f7 15e 25 25 15e 25 1f7 1f7 bdc 1f7 bdc 1f7 1f7 1f7 1f7 b0 b0 1f7 1f7 1f7 
           1f7 1f7 1f7 1f7 1f7 1f7 1f7 25e 25e b0 b0 b0 b0 b0 b0 1f7 b0 b0 1f7 b0 b0 b0 b0 26 
           f7 f7 15e 15e 15e 15e b0 b0 26 26 f7 f7 f7 26 bdc 15e bdc 15e 5e f7 f7 f7 f7 26 f7 
           f7 15e bdc f7 f7 f7 bdc bdc bdc f7 f7 15e 15e 15e 15e 1f7 1f7 1f7 1f7 b0 b0 b0 1f7 
           1f7 1f7 1f7 1f7 15e 15e 1f7 25e 25e 25e 25e 25e 25e 25e 25e 25e 25e 25e b0 b0 b0 b0 
           b0 b0 1f7 1f7 b0 b0 b0 15e 15e f7 15e 15e f7 f7 f7 f7 15e 15e f7 f7 f7 f7 15e 15e 
           bdc f7 15e 15e 15e 25 15e 15e f7 b0 f7 15e f7 bdc bdc bdc bdc f7 bdc bdc bdc 15e 25 
           25 f7 1f7 bdc bdc bdc b0 b0 b0 b0 1f7 b0 b0 b0 b0 b0 b0 b0 f7 f7 25 bdc bdc bdc bdc 
           bdc bdc bdc 25e 1f7 1f7 b0 b0 b0 b0 1f7 b0 b0 b0 f7 f7 15e f7 f7 25 f7 f7 15e f7 15e 
           15e 15e 15e 26 26 b0 b0 f7 15e 15e b0 b0 25 15e 15e f7 b0 b0 15e f7 f7 15e f7 15e f7 
           f7 f7 bdc bdc bdc bdc bdc bdc 1f7 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 25e 
           25e 25 25e 25e 25e 25e 25 bdc bdc b0 b0 b0 b0 b0 b0 b0 b0 bdc 26 15e f7 25 15e 15e 
           15e f7 25 25 f7 f7 25 15e 15e b0 b0 b0 b0 b0 b0 b0 b0 25 25 15e 15e f7 b0 b0 15e 15e 
           15e 25 15e 15e 15e 15e 15e 25 15e 15e 15e 1f7 b0 b0 b0 b0 b0 b0 25e 25e 25e bdc b0 
           b0 b0 b0 b0 25e 25e 25e bdc bdc bdc 25e 25e bdc 25e 25e b0 b0 b0 b0 b0 b0 b0 b0 f7 
           bdc bdc bdc bdc bdc bdc bdc bdc f7 f7 15e 15e b0 b0 b0 b0 b0 b0 b0 b0 b0 15e b0 f7 
           f7 f7 15e f7 b0 b0 b0 f7 15e 15e 15e 25 25 15e 15e 25 15e f7 f7 f7 b0 b0 b0 b0 25e 
           25e 25e 25e bdc 25e 25e 25e 25e 25e 25e 25e bdc bdc 25e 25e 25e bdc bdc 25e 25e 25e 
           b0 b0 b0 b0 b0 b0 b0 f7 f7 bdc f7 f7 f7 25 25 f7 f7 f7 26 b0 b0 b0 f7 15e b0 b0 b0 
           b0 b0 f7 15e b0 b0 b0 b0 15e 15e f7 f7 15e b0 b0 b0 15e 15e 15e 25 15e 25 26 25 f7 
           25 f7 25 25e 25e 25e 25e 25e 25e bdc 25e 25e 25e bdc bdc bdc bdc 25e 25e 25e 25e 25e 
           25e 25e 25e 25e 25e 25e b0 b0 b0 b0 b0 b0 b0 b0 b0 f7 f7 f7 f7 f7 25e f7 f7 f7 b0 f7 
           b0 b0 b0 b0 b0 b0 b0 b0 15e f7 b0 b0 b0 b0 b0 b0 15e 25 f7 f7 f7 b0 15e 15e 15e f7 
           15e 15e 15e b0 25e b0 25e 25e 25e 25e 25e 25e 1f7 1f7 bdc bdc bdc bdc 25e 25e 25e 
           bdc 25e 25e 25e 25e 25e 25e 25e 25e 25e 25e 25e 25e 25e 25e 25e 25e b0 b0 b0 b0 b0 
           f7 f7 f7 25e 25e f7 f7 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 f7 f7 b0 b0 b0 b0 b0 b0 b0 
           15e 15e b0 f7 b0 15e 15e 15e 15e f7 b0 b0 b0 25e 25e 25e 25e 25e 25e 25e 1f7 1f7 1f7 
           1f7 1f7 25e 25e 25e 25e 25e bdc 1f7 bdc bdc bdc 25e 25e 25e 25e 25e 25e 25e 25e 25e 
           25e 25e 25e b0 b0 b0 b0 25e b0 b0 b0 b0 b0 b0 b0 b0 b0 25e 25e 25e 25e b0 b0 b0 b0 
           b0 b0 b0 b0 b0 b0 f7 f7 15e 15e 15e 15e b0 b0 b0 b0 15e 15e 15e 15e 15e 15e b0 25e 
           25e 25e 25e 25e 25e 25e 25e 1f7 1f7 25e 25e 25e 25e 25e 25e bdc 1f7 1f7 1f7 1f7 1f7 
           bdc bdc 1f7 1f7 1f7 25e 25e 25e 25e 25e 25e 25e b0 f7 f7 1f7 1f7 25e 25e 25e 25e 25e 
           25e 25e 25e 25e 25e 25e 25e 25e 25e 25e 25e 25e 25e f7 f7 b0 b0 b0 f7 f7 f7 15e b0 
           b0 b0 b0 b0 b0 b0 15e 15e 15e 25 b0 15e b0 25e 25e 25e 25e 25e b0 25e 25e 25e 25e 
           25e b0 1f7 1f7 25e bdc 1f7 15 15 15 15 15 bdc bdc bdc 15 15 15 15 25e 25e 25e 25e f7 
           f7 25e 25e 25e 25e 15 25e 15 25e 15 25e b0 25e 25e 25e 15 b0 25e 25e 25e 25e f7 f7 
           f7 f7 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 15e 25 b0 b0 b0 b0 b0 25e b0 b0 b0 
           b0 b0 b0 b0 b0 b0 b0 b0 25e 25e 1f7 bdc bdc bdc bdc bdc 15 15 15 15 bdc bdc bdc 15 
           15 25e 25e 25e 25e 25e 25e 25e 15 15 15 15 15 15 15 15 15 15 15 25e 25e f7 f7 b0 f7 
           f7 f7 f7 f7 f7 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 25 15e 15e b0 b0 
           b0 b0 b0 b0 b0 b0 15e f7 b0 b0 1f7 25e 15 15 15 15 15 15 15 bdc bdc bdc bdc 15 15 15 
           bdc bdc 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 
           15 b0 15 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 
           b0 b0 b0 b0 b0 b0 b0 b0 1f7 25e 25e 15 15 25e 15 15 15 15 15 15 bdc bdc bdc bdc 15 
           bdc 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 
           15 15 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 
           b0 b0 b0 b0 b0 b0 1f7 25e 15 15 15 15 15 15 15 15 15 15 15 15 15 15 bdc bdc bdc 15 
           15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 
           15 15 15 b0 b0 b0 b0 b0 b0 b0 b0 f7 15 15 15 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 b0 
           b0 b0 1f7 15 b0 25e 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 bdc bdc bdc 15 15 
           15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 
           15 15 b0 b0 b0 b0 b0 b0 15 15 15 15 15 15 15 15 15 15 b0 b0 b0 bdc bdc f7 15 15 15 
           15 15 25e 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 
           15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 
           15 15 b0 b0 b0 15 15 15 15 15 15 15 15 15 15 15 15 f7 bdc f7 15 15 15 15 15 25e 15 
           15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 
           15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 
           15 15 15 15 15 15 15 15 15 15 15 15 15 15 bdc 15 b0 15 15 15 b0 25e 25e 15 15 15 15 
           15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 
           15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 15 
           15 15 15 15 15 15 15 15 15 f7 bdc 15 15 b0 15 15 b0 15 25e 15 15 15 15 15 15 15 15 
           15 15 15 15 15 15 15 15 15 15 ] 

: mapsize ( -- n)
        X Y Z * * cells ;                              | note reverse polish notation

: fill-map ( xt-c | 0 --)
       | " filling..." msg
        0 0 terrain xyz>a dup mapsize + swap do        | for every terrain square in the map
           dup ?execute i w!                           | store fill character
           Z cells 1- skip
        loop  drop ;

: 0map ( --)
        map dup mapsize +
        swap do
           0 i c!
        loop ;

: blaze ( xt-c xt-alg --)
        | " drawing..." msg
        execute                                        | process the algorithm at xt-alg
        0tracks  temp off xreset
        | stack) off                                   | reset for next time
;

: .map ( --)
        map dup mapsize +
        swap do                                        | for the entire map,
           i w@ if                                     | if the square is non-zero,
              i .square                                | colour and print.
           then                                        | otherwise
           1 cells 1- skip                             | (try the next layer/square)
        loop  cr ;                                      

: terrain: ( xt -- )
        create , does> ( n-limit a --)
        swap 0 ?do ( a)
           dup @execute ( a xt-c xt-alg | a xt-c1 xt-c2 xt-alg)
           blaze ( xt)
        loop  drop ;

| terrain packs
        ' hill) terrain: hills     ' ice) terrain: icecaps   ' lake) terrain: lakes
        ' river) terrain: rivers   ' road) terrain: roads    ' rock) terrain: rocks
        ' sand) terrain: sands     ' snow) terrain: snows
        ' stonehouse terrain: stonehouses
        ' brickhouse terrain: brickhouses
        ' pen terrain: pens
: streams  ( n --)  water swap 0 ?do  256 + dup to thiswater dup ['] river-alg blaze  loop  drop ;
: terrain1 ( n --)  0 ?do  11 rand ?terrain1 blaze  loop ;
: terrain2 ( n --)  0 ?do   7 rand ?terrain2 blaze  loop ;

| : convert ( c -- c')
|        case
|           32 of ocean endof    'S of desert endof    '= of river endof
|           '- of grassl endof   '^ of hill endof      '> of hill2 endof
|           '* of mount endof    '& of conifer endof   '` of steppe endof
|           '% of bleaf endof    'i of ice endof
|           ." couldn't find " emit
|        endcase ;

: inline>map ( a-inline-map --)
        map dup mapsize +
        swap do ( a)
           dup w@ ( a c)
           i >terrain w! ( a)
           2+ ( a')
           Z cells 1- skip
        loop  drop ;

: outworld ( --)
        ['] ocean fill-map
        1 icecaps  26 terrain1  1 icecaps  12 rivers
        ['] ocean shave-alg ;

: inworld ( --)
        10 terrain2
        3 rand
        dup 0if  3 rand snows  else
        dup 1if  3 rand sands
        then then  drop
        4 rand streams  1 lakes  3 rand roads 
        4 rand pens  7 rand stonehouses  9 rand brickhouses ;

: rand-world ( --)
        9 rand
        dup 0if  drop europe inline>map  ;then
        dup 1if  drop  outworld  ;then
        2 5 >< if  ['] grass  else  ['] prairie  then
        fill-map inworld ;

| •••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
|                                        £££ £    £  £ £
|                                        £_£ £   £_£ £_£
|                                        £   £££ £ £  £
|                                        ••••••••••••••

: get-key ( -- k)
        | repeat
|            0 Y gotoxy 40 ms key? not                   | wait until a key is pressed
 |        while
        ekey
        .border
        ?say-wipe                                      | clear any messages or speech
        dup valid-key? 0if                              | if invalid key
           drop err get-key                             | wait until a key is pressed
        then ;

: obstacles? ( c -- t)
        dup >r water =  r@ citywall = or  brick r@ = or  stone r@ = or  door+ r@ = or
        door++ r@ = or  door+++ r@ = or  door++++ r@ = or  window+ r> = or ;

: unique ( n -- n | n')
        :[ @ w@ over <> dup 00; drop ]; census iterate ( n 0 0 | n -1 -1)
        dup not 0; 2drop 256 + unique ;

: .people ( list --)
        :[ @ w@ . space true ]; census iterate cr ;

: populate ( list --)
        :[ @ dup w@ swap location xyz>a w! true ]; swap iterate ;

: rand-job ( -- glyph)
        254 rand 1+ dup npc? 0if                       | roll any glyph, but if it's a non-npc one
           drop rand-job                               | try again
       ;then                                           | else
        unique ;                                       | make sure it's unique

: rand-race ( -- race)
        14 rand 1000 + ;

: rand-xyz ( -- x y z)
        X rand Y rand
        2dup terrain xyz>a w@ filter ( x y c)          | roll a random location, fetch terrain there
        obstacles? if ( x y)                           | if there's an obstacle
           2drop rand-xyz                              | try again
       ;then                                           | else,
        above ;

: person ( --)
        255 dup allocate dup >r
        swap 0 fill                                    | fill with zero's
        r@ census link                                 | add to census list
        rand-job dup r@ w!                             | store glyph
        rand-race r@ race w!                           | roll random race, store
        rand-xyz r@ xyz!                               | roll random xyz, store
        10 r@ energy c!                                | store 10 energy points
        traveler?
        if                                             | able to venture beyond home? 
           true r@ traveler c!                         | set flag
        then
        20 r@ init c!                                  | set initiative
        50 r> skill c! ;                               | set skill

: people ( n --)
        0 ?do  person  loop ;

: get-init ( a -- n)
        @ init roll ;

: init-rolls  ( list -- list node n node n...)         | return all nodes and init rolls in list
        temp off
        dup dup @
        :[ dup get-init swap get-node temp ++ true ]; rot iterate
        drop ;

: turns ( -- list node n node n...)
        census init-rolls ;

: queue ( list node n node n... --)
        sort relink ;

| : who's-turn ( -- a-me)
|        player 0                                       | fake val, just to kick things off
|        :[ @ dup init roll rot 2dup >if  drop rot drop  else  nip nip  then  true ];
|        census iterate drop ;

: 1-round ( -- t)
        @ dup to me
        player =if get-key else 8 rand then            | get key input, else npc's move at random
        | .info                                        | print info
        me +turns                                      | increment turns
        act                                            | process actor's action
        in-map? @ ;

: GO! ( --)
        in-map? on
        turns queue
        ['] 1-round census iterate
        in-map? @ 0; drop                             | unless hero exits map,
        GO! ;                                          | actors continue taking turns

: next-xyz ( a-me --)                                  | calculate new position after exiting map edge
        dup wipe
        dup location drop ( a-me x y )
        dup 0if  drop Y 1-  else  dup Y 1- =if  drop 0  then then  swap
        dup 0if  drop X 1-  else  dup X 1- =if  drop 0  then then  swap
        rot above swap xyz! ;

: ?name ( --)
        noop ;

: play ( --)
		cr ver type cr
        1000 ms

        .menu                                          | display menu
        rand-world                                     | below a random map
        ?name
        outworld? 0if                                  | if not in outworld,
           1 people                                    | generate people
        then                                           | else/then
        census populate .map                           | populate and print map
        
           GO!                                         | hero and npc's take turns moving around
                                                       | until hero passes map edge
        player next-xyz                                | calculate next position for hero
        0map                                           | clean up
        play ;                                         | play again...

: test)  cls
        0map ['] grass fill-map .map
        " streams" msg 3 streams .map
        " roads"   msg 2 roads .map
        " pens"    msg 4 pens .map
        " stone"   msg 5 stonehouses .map
        " brick"   msg 6 brickhouses .map
        " display..." msg .map ;
: test ['] test) bench ;


| code to make executable: change '1' to '0' below:
with~ ~sys
' play is appstart
1 [IF]
   play
[ELSE]
   " caravan" makeexename (save) bye
[THEN]

| ** TODO **
| map array should only contain terrain and footprints, everything else is printed
| by iterating over a linked list of actors, items and hidden objects


| •••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
|                                        ££   £  £££  £
|                                        £ £ £-£  £  £-£
|                                        ££  £ £  £  £ £
|                                        •••••••••••••••
