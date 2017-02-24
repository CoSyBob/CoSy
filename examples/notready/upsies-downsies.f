| SNAKES'n'LA--wait no, UPSIES-DOWNSIES
: +++ ." ++++++++++++++++" cr 800 ms ;

needs os/fakeconsole
needs alg/array
needs alg/stack
needs random/gm
~sys make prompt  .s ." ok> " ; exit~

context: ~game
~struct ~game

defer validkey?

   variable stack)
: .stk ( --)                                         | print contents of data stack to screen
       0 17 stack) @ dup>r + gotoxy r> (.) type ." ." .s stack) ++ ;

| ooooooooooooooooooOooooooooooooooooo
| GiN ::::: BeGiN ::::: BeGiN ::::: Be
| ooooooooooooooooooOooooooooooooooooo

    0 null !
     '_ value tile
       3 value heart                                   | roll again, destroy a down, +1 to dice
       '# value border
        '\ value ramp1
        '/ value ramp2
        '@ value human
      179 value down
     197 value up
      1 value #players
    'S value screen-key
    32 value roll-key
    'Q value quit-key
     60 value speed
      16 value cols
        16 value rows
          6 value die
              stack frozens                            | stores frozen players until freed
                list keys                              | all keyboard commands
                  list sides                           | where the ramps are
                   list players                        | all players
         rows cols 2array board                        | our game board array, created at runtime



| ooooooooooooooooooOooooooooooooooooo
| oLs ::::: tOoLs ::::: tOoLs ::::: tO
| ooooooooooooooooooOooooooooooooooooo

: seed  ms@ dup 2dup seed4 ;
: rnd ( max -- n<max) rand swap mod abs ;

: swapper ( data1 data2 <name> --)
   create , ,
   does> dup @ swap 2dup cell+ xchg swap ! ;

: rnd[] ( -- a)  size rnd cells ary @ + ;              | a random board square
: start[] ( -- a)  1 rows 2 - xy>a ;                   | players' starting square
: win[] ( -- a)  1 1 xy>a ;                            | arrive here to win the game

: center ( u -- )
        cols swap - 2/ 1- abs rows gotoxy space ;
: msg ( a u --)
        yellow bold fg 0 rows gotoxy cols 2* spaces       | center string below the board and print
        dup center type space normal ;

    ' W ' E swapper otherway
    false true swapper mode?
    ramp1 ramp2 swapper ramp



| ooooooooooooooooooooooOoooooooooooooooooooooo
| hIcS ::::: gRaPhIcS ::::: gRaPhIcS ::::: gRaP
| ooooooooooooooooooooooOoooooooooooooooooooooo

: pos+  pos@ 1+ gotoxy savepos ;

: .dice ( n --)
        cyan fg
        cols 2 + 9 gotoxy savepos
       ."  ____"
        pos+ ." |\\ __`"
        pos+ ." |" 250 emit ." |   |"
        pos+ ." |" 250 emit ." | " white fg . cyan fg ." |"
        pos+ ."  \\|___|"
        normal ;

: 2red  red fg 2 rnd 0; drop bold red fg ;
: 2green  green fg 2 rnd 0; drop bold green fg ;
: 2grey  2 rnd 0if black bold fg ;then white fg ;

: colours ( c --)
        case
           up of 2green endof
           down of 2red endof
           human of cyan bold fg endof
           border of black bold fg endof
           heart of magenta bold fg endof
           drop 2grey
        endcase ;

: .[] ( a --)
        dup a>xy gotoxy                                | go to screen position,
        (pek) dup colours emit                         | fetch and colour data, then print.
        normal ;                                       | restore to default colour



| ooooooooooooooooooOooooooooooooooooo
| aRd ::::: bOaRd ::::: bOaRd ::::: bO
| ooooooooooooooooooOooooooooooooooooo

: .preview ( c a -- c a)
        2dup a>xy gotoxy emit 0 ms ;

: 0board ( --)
        all 2dup swap . .  cr do                                         | for the entire board
		+++
           i dup (rmv) 0 swap (psh)                    | remove every stack, then store a zero
           3 skip
        loop ;

: .board ( --)
        all do                                         | for the entire board,
           i (pek) if i .[] then                       | if the square is non-zero, colour and print
           3 skip                                      | then advance to next square
        loop cr ;

: tiles ( xt-dir a -- xt-dir a t)
        over execute tile over .preview (pok) ( xt a')
        2dup swap execute (pek) border <> ;
: ramp'n'link ( a c -- a)
        over .preview (pok) dup ins ;
: ramps ( xt-dir a -- a)
        nip  32 ramp'n'link  S ramp ramp'n'link ;
: fixups ( a --)
        border over (pok) N tile swap (pok)
        32 start[] tuck (pok) sides del
        16 win[] (pok) ;
: ramps'n'tiles ( -- a-last)
        sides
        0 1 xy>a                                       | set sides as current list
        rows 2 - 0do
           otherway swap
           repeat tiles while
           ramps
        loop
        fixups ;

: border! ( x y --)
        xy>a border swap .preview (pok) ;
: borders ( --)
        cols 0do i 0 border! i rows 1- border! loop
        rows 0do 0 i border! cols 1- i border! loop ;

: tile? ( a -- t)
        (pek) tile = ;

: -tileN/S? ( xt-dir a a -- xt-dir a t)
        dup tile? 0; drop
        2 pick execute tile? not ;

: slide ( c xt-dir --)
        rnd[] ( c xt a)
        -rot 2 pick ( a c xt a)
        cols 2/ rnd 1+ 0do
           dup -tileN/S? if
              drop 3drop unloop
           ;then ( a c xt a)
           2 pick over .preview (pok) ( a c xt a)
           over 4 pick ( a c xt a xt) (-psh)           | setup slides
           over execute ( a c xt a')
        loop drop 3drop ;
: slides ( n c xt-dir --)
        rot 0 ?do 2dup slide loop 2drop ;
: ups ( n --)
        up ['] N slides ;
: downs ( n --)
        down ['] S slides ;

: specials ( n c --)
         swap 0 ?do dup rnd[] ( c c a)
            dup tile? 0if
               2drop remains 1+  unloop swap specials
            ;then
            .preview (pok)
         loop drop ;



| oooooooooooooooooooOooooooooooooooooooo
| IoN ::::: aCtIoN ::::: aCtIoN ::::: aCt
| oooooooooooooooooooOooooooooooooooooooo

:: keys fnd ; is validkey?

: getkey ( -- k)
        repeat 40 ms key? not while ekey               | wait until a key is pressed
        dup validkey? if                               | if valid
           undo validkey?                              | exit,
       ;then drop getkey ;                             | else continue waiting

: roll ( -- n)
        die rnd 1+ dup .dice ;

: ?quit ( --)
        " Quit? (y/n)" msg
       { dup 'y = swap 'n = or } >defer validkey?
        getkey 'y = throw " " msg ;
: "quit" ( --)
        normal " So long!" msg cr  1 cursor ;

: whichway ( a -- xt-direction)
        a>xy nip 2 mod 0if ['] E ;then ['] W ;
: -whichway ( a -- xt-direction)
        dup whichway ['] E = if ['] W ;then ['] E ;
: wipe ( c a a' -- c a')
        >r 2dup (del) .[] r> ;
: .new ( c a a' -- c a')
        wipe 2dup (psh) dup .[] speed ms ;
: back ( a - a')
        -whichway execute .new dup
        dup sides fnd 0; drop S back ;
: ahead ( a -- a')
        dup whichway execute .new dup
        dup sides fnd 0; drop N ahead ;
: win? ( c a -- c a | a t)
        dup win[] = 0; drop
        nip unloop unloop false ;
: line? ( a -- t)
        (-pek) dup ['] N = swap ['] S = or ;
: slide ( c a -- c a')
        dup 1 (th) ( c a node)
       { >r dup r> @execute .new true }
        swap iterate ;
: .announce ( c a u --)
        msg dup colours emit yellow bold ." !" ;
: choose-player ( c a -- c a c-player)
        over human =if
          { players fnd } >defer validkey?
           getkey
        ;then
         players num rnd th cell+ @ dup
            3 pick = 0; 2drop choose-player ;
: freeze ( c a -- c a)
        choose-player
        dup del
        dup frozens psh 4 rnd 2 + 0do 0 psh loop
        " You're frozen" .announce 750 ms ;

: chance ( c a -- c a')
        players num 1 >if 3 rnd else 2 rnd then
        case
           0 of " Back 3 spaces!" msg 3 0do dup back .new loop endof
           1 of " Ahead 3 spaces!" msg 3 0do dup ahead .new win? loop endof
           2 of " Freeze which player?" msg freeze endof
        endcase ;
: ?event ( c a -- c a')
        dup line? if slide ?event ;then
        heart over (fnd) 0;
        tile swap !  chance ;

: move ( c a n -- c a')
        0do
           dup ahead                                   | move ahead, leveling up if necessary
           .new win?                                   | print player at new location, see if we've won
        loop ?event drop ;                             | after moving, check if we're at a slide or heart

: act ( c a k -- a' | false)
        case
           roll-key of roll move endof
           quit-key of ?quit getkey act endof
           screen-key of mode? fullscreen getkey act endof
           drop
        endcase ;



| ooooooooooooooooOoooooooooooooooo
| aY ::::: pLaY ::::: pLaY ::::: pL
| ooooooooooooooooOoooooooooooooooo

: keys! ( --)
        keys  roll-key ins quit-key ins screen-key ins 'y ins 'n ins ;

: #players? ( --)
        " players? (1-9)" msg
       { '1 '9 between } >defer validkey?
        getkey digit> to #players ;

: start[]! ( --)
        start[] { @ over (psh) true } players itr    | copy each player from list to start square
        drop ;
: start ( --)
        players
        #players 0do i '@ + ins loop                   | store all players in list
       { 2drop roll roll > } >defer compare          | roll to see who goes first, 
        srt start[]! ;                                 | populate start square accordingly
: setup ( --)
        0board borders 
		ramps'n'tiles
        14 ups  14 downs  12 heart specials
        #players? start ;

: melt ( c --)
        dup " You're free" .announce 750 ms players ins ;
: ?frozen ( -- c t)
        frozens num 0; drop pop 0; melt ;
: search ( c -- a | failed: c)
        all do
            dup i (fnd) if drop i unloop ;then
            3 skip
         loop ;
: GO! ( --)
        ?frozen                                        | continue melting any frozen players
        0 { nip @ dup " Go" .announce ( c)            | announce player's turn
           dup search over ( c a c)                    | search board for the current player
           human =if getkey else 32 then               | if human, wait for keypress, else roll.
           act dup }
        players itr
        0; drop GO! ;

: blink ( a -- a)
        dup (pop) over .[] speed ms over (psh) dup .[] speed ms ;
: victory ( a --)
        dup (pek) " You win" msg emit yellow bold fg ." !"
        6 0do yellow blink fg loop drop ;
: cleanup ( --)
        players rmv  sides rmv  frozens rmv ;
: ?again ( --)
        " Again?" msg
       { dup 'y = swap 'n = or } >defer validkey?
        getkey 'n = throw " " msg ;

: game ( --)
        setup .board GO! victory cleanup ?again game ;

: instructions ( --)
        cols 2 + 0 gotoxy savepos
        pos+ ." Welcome to " green bold fg ." Upsies" normal ." -" red bold fg ." Downsies" normal ." ,"
        pos+ ." the game of mInD-nUmBiNg StRaTeGy!"
        pos+ ." "
        pos+ ." <space> ... roll die"
        pos+ ." <" quit-key emit ." > ....... quit game"
        pos+ ." <" screen-key emit ." > ....... fullscreen" ;

: play ( --)
        0 cursor
        " Upsies-Downsies" title
        seed  keys!                                    | seed RNG, store keyboard commands
        cols rows (2array) ['] board !                 | create board
        board                                          | activate
        instructions
        repeat                                         | start game and keep playing
           ['] game catch if cleanup "quit" ;then      | until 'Q'uit button pressed
        again ;



: exe ( --)
        " ~sys ' play is appstart exit~ nosavedict on save upsies-downsies.exe" eval ;

play
