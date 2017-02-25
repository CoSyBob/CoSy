( VI-like editor for Reva Forth, by Tommy Lillehagen 2007. )

needs os/console
needs string/misc

      16 constant #BLOCKS   ( number of blocks per file )
1024 dup constant /BLOCK    ( characters per block )
  64 dup constant /LINE     ( characters per line )
       / constant #LINES    ( number of lines per block )
         variable LN        ( current line   0..#LINES-1 )
         variable COL       ( current column 0../LINE-1 )
         variable COUNT     ( action repeat count )
         variable BLOCK#    ( current block )

create BLOCKS /BLOCK #BLOCKS * allot
BLOCKS /BLOCK #BLOCKS * 32 fill

create BLOCK /BLOCK allot
create LINE /LINE 1+ dup allot LINE swap 32 fill 

( caret words )
: caret     ( -- )      COL @ 3 + LN @ 1+ gotoxy normal ;
: position  ( -- # )    LN @ /LINE * COL @ + ;
: ln--      ( -- )      LN @ 0; drop LN -- caret ;
: ln++      ( -- )      LN @ #LINES 1- < 0; drop LN ++ caret ;
: col-home  ( -- )      COL off caret ;
: col-end   ( -- )      /LINE 1- COL ! caret ;
: col--     ( -- )      COL @ 0if LN @ 0; drop
                        ln-- col-end ;then COL -- caret ;
: col++     ( -- )      COL @ /LINE 1- < 0if LN @ #LINES 1- <
                        0; drop ln++ col-home ;then
                        COL ++ caret ;
: ln-first  ( -- )      LN off caret ;
: ln-last   ( -- )      #LINES 1- LN ! caret ;
: goto      ( # - )     /LINE /mod LN ! COL ! caret ;
: word-left ( -- )      position repeat 1- dup BLOCK + c@ 32
                        =if dup 0 < not if goto then ;then
                        dup while drop ;
: word-rght ( -- )      position repeat 1+ dup BLOCK + c@ 32
                        =if dup /BLOCK <if goto then ;then
                        dup while drop ;

( UI words )
variable special-status
: bgreen/green bold green green color ;
: bgreen/black bold green black color ;
: black/black black black color ;
: black/white black white color ;

: title-bar 0 0 gotoxy bgreen/green 2 spaces bgreen/black 
    ."  VIED " bgreen/green /LINE 5 - spaces ;
: current-block /LINE 6 - 0 gotoxy bgreen/green 
    ." block:" BLOCK# @ 2 .r caret ;
: line# black/black #LINES 1+ 1 do 0 i gotoxy i 2 .r loop ;
: status-pos 0 #LINES 1+ gotoxy ;
: status-bar status-pos black/white /LINE 3 + spaces ;
: status-lc status-pos bold black/white 
    space LN @ 1+ 2 (.r) type ': emit COL @ 1+ 2 .r
    '# emit black/white COUNT @ 3 .r caret ;
: status status-bar status-lc ;
: message ( $- ) 12 #LINES 1+ gotoxy black/white type caret ;
: update-line dup 3 over 1+ gotoxy
    /LINE * BLOCK + LINE /LINE move LINE /LINE type caret ;
: lines #LINES 0 do i update-line loop ;
: screen cls title-bar line# status lines ;

( block words )
: put         ( c -- )  position BLOCK + c! ;
: iput        ( c -- )  position BLOCK + dup 1+ /LINE COL
                        @ - 1- cmove> position BLOCK + c! ;
: remove      ( -- )    position BLOCK + dup 1+ swap
                        /LINE COL @ - 1- move 32
                        LN @ 1+ /LINE * BLOCK + 1- c! ;
: line-after  ( -- )    LN @ 1+ /LINE * BLOCK + dup /LINE + dup
                        BLOCK /BLOCK + swap - 1+ cmove>
                        LN @ 1+ /LINE * BLOCK + /LINE
                        32 fill lines ;
: line-before ( -- )    LN @ /LINE * BLOCK + dup /LINE + dup
                        BLOCK /BLOCK + swap - 1+ cmove>
                        LN @ /LINE * BLOCK + /LINE
                        32 fill lines ;
: bfname ( -- a c )     " blocks" ;
: fetch-block ( -- )    BLOCK# @ /BLOCK * BLOCKS + BLOCK /BLOCK
                        move lines current-block ;
: write-block ( -- )    BLOCK BLOCK# @ /BLOCK * BLOCKS + /BLOCK
                        move ;
: load-blocks ( -- )    bfname open/r ioerr @ not 0drop; drop
                        >r BLOCKS /BLOCK #BLOCKS * r@ read drop
                        r> close BLOCK# off fetch-block ;
: save-blocks ( -- )    write-block bfname creat >r BLOCKS
                        /BLOCK #BLOCKS * r@ write r>
                        close lines ;

( keyboard handler words )
'0 padchar !
: unknown ( -- ) " unknown command" message COUNT off ;
: exec? ( @|0 -- ) dup 0if drop unknown ;then status execute
    special-status @ 0if special-status off status then ;
: key>xt ( n -- @ ) 4 (.r) find dup 0if -rot 2drop then ;
: command ( -- ) ekey key>xt exec? command ;
: repeat-action ( xt -- ) COUNT @ 0 do dup execute loop drop ;

( editor words )
: backspace ( -- ) col-- remove ;
: delete ( -- ) remove ;
: replace-loop ( -- ) ekey
    dup 27 =if drop ;then
    dup 128 >if key>xt exec? ;then
    dup 10 =if drop ln++ col-home status-lc replace-loop ;then
    dup 8 =if drop backspace LN @ update-line replace-loop ;then
    dup 32 <if drop 32 then
    put LN @ update-line col++ status-lc replace-loop ;
: replace-mode ( -- ) " replace mode" message replace-loop ;
: insert-loop ( -- ) ekey
    dup 27 =if drop ;then
    dup 128 >if key>xt exec? ;then
    dup 10 =if drop line-after ln++ col-home insert-loop ;then
    dup 8 =if drop backspace LN @ update-line insert-loop ;then
    dup 32 <if drop 32 then
    iput LN @ update-line col++ status-lc insert-loop ;
: insert-mode ( -- ) " insert mode" message insert-loop ;

( keycode       | key handlers                                 )
( --------------+----------------------------------------------)
: 0003 ( ctrl+c ) bye ;
: 0005 ( ctrl+e ) cls BLOCK /BLOCK eval cr
                  ." Press any key to continue... " ekey drop
                  screen COUNT off ;
: 0019 ( ctrl+s ) save-blocks COUNT off ;
: 0012 ( ctrl+l ) load-blocks BLOCK# off COUNT off ;
: 0260 ( left   ) ['] col-- repeat-action COUNT off ;
: 0261 ( right  ) ['] col++ repeat-action COUNT off ;
: 0259 ( up     ) ['] ln-- repeat-action COUNT off ;
: 0258 ( down   ) ['] ln++ repeat-action COUNT off ;
: 0262 ( home   ) col-home COUNT off ;
: 0358 ( end    ) col-end COUNT off ;
: 0331 ( insert ) insert-mode COUNT off ;
: 0105 ( i      ) insert-mode COUNT off ;
: 0114 ( r      ) replace-mode COUNT off ;
: 0097 ( a      ) col++ insert-mode COUNT off ;
: 0010 ( return ) line-after ln++ col-home insert-mode
                  COUNT off ;
: 0111 ( o      ) line-after ln++ col-home insert-mode
                  COUNT off ;
: 0079 ( O      ) line-before col-home insert-mode COUNT off ;
: 0330 ( delete ) position ['] delete repeat-action goto
                  COUNT off lines ;
: 0008 ( backsp ) ['] backspace repeat-action COUNT off lines ;
: 0009 ( tab    ) ( TODO ) ;
: 0443 ( c-left ) ['] word-left repeat-action COUNT off ;
: 0444 ( c-rght ) ['] word-rght repeat-action COUNT off ;
: 0480 ( c-up   ) ln-first COUNT off ;
: 0481 ( c-down ) ln-last COUNT off ;
: 0339 ( pgup   ) write-block BLOCK# @ 0; drop BLOCK# --
                  fetch-block LN off COL off caret ;
: 0338 ( pgdown ) write-block BLOCK# @ #BLOCKS 1- <if BLOCK# ++
                  fetch-block LN off COL off caret then ;
: 0048 ( 0      ) COUNT @ 10 * COUNT ! ;
: 0049 ( 1      ) COUNT @ 10 * 1+ COUNT ! ;
: 0050 ( 2      ) COUNT @ 10 * 2 + COUNT ! ;
: 0051 ( 3      ) COUNT @ 10 * 3 + COUNT ! ;
: 0052 ( 4      ) COUNT @ 10 * 4 + COUNT ! ;
: 0053 ( 5      ) COUNT @ 10 * 5 + COUNT ! ;
: 0054 ( 6      ) COUNT @ 10 * 6 + COUNT ! ;
: 0055 ( 7      ) COUNT @ 10 * 7 + COUNT ! ;
: 0056 ( 8      ) COUNT @ 10 * 8 + COUNT ! ;
: 0057 ( 9      ) COUNT @ 10 * 9 + COUNT ! ;
: 0103 ( g      ) COUNT @ dup 1 #LINES between
                  0if drop COUNT off ;then
                  1- LN ! caret COUNT off ;
: 0104 ( h      ) " dec:" position BLOCK + c@ dup >r (.) strcatf
                  "  hex:" strcatf hex r@ (.) strcatf
                  "  oct:" strcatf octal r> (.) strcatf
                  message decimal special-status on COUNT off ;

( TODO m -> enter map definition )

screen      ( draw screen      )
fetch-block ( initialize block )
command     ( keyboad handler  )
