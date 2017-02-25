| tictactoe.f
|
| A simple perfect playing (at leat I hope so ;))
| tic tac toe game for Reva FORTH
|
| Author: Danny Reinhold / Reinhold Software Services
| Reva's license terms also apply to this file

needs os/console


create board 9 allot

'. constant empty
'X constant X
'O constant O

variable currentPlayer
variable move-value   | just an informative variable...


: toggle-player  currentPlayer @ 'X =if 'O else 'X then currentPlayer !  ;


: init  0 move-value !  X currentPlayer !  board 9 empty fill ;


: display
  cls
  ." TicTacToe - a perfect playing game for Reva FORTH" cr
  ." Author: Danny Reinhold / Reinhold Software Services" cr
  cr
  3 0do
    3 0do
      j 3 * i +   | field-index
      dup board + c@  | field-index field-value
      dup empty =if drop space 1+ . else space emit space drop then
|      space emit space
      i 2 <if '| emit then
    loop

    cr
    i 2 < if  ." ---|---|---" cr  then

  loop
  cr
  ." The value of my last move: " move-value @ . cr
  cr
;


| returns the number of empty fields (ie the number of possible moves)
: #moves
  0
  9 0do
    board i + c@ empty =if 1+ then
  loop
;


: win-row?  ( player row -- player winflag )
  swap >r
  board +
      dup c@ r@ = swap  | flag1 addr
  3 + dup c@ r@ = swap  | flag1 flag2 addr
  3 +     c@ r@ =       | flag1 flag2 flag3
  and and

  r> swap
;


: win-col?  ( player col -- player winflag )
  3 * board +  | player addr
  swap >r
  dup c@ r@ = swap    | flag1 addr
  1+ dup c@ r@ = swap | flag1 flag2 addr
  1+     c@ r@ =      | flag1 flag2 flag3
  and and

  r> swap
;

: win-dia?  ( player -- player winflag )
  | dialognal from upper left to bottom right
  >r
  board    dup c@ r@ =
  swap 4 + dup c@ r@ =
  swap 4 +     c@ r@ =
  and and

  | diagonal from upper right to lower left
  board 2 + dup c@ r@ =
  swap  2 + dup c@ r@ =
  swap  2 +     c@ r@ =
  and and

  or
  r> swap
;


: win? ( player -- winflag )

  3 0do
    i win-row? if drop -1 unloop ;then
  loop

  3 0do
    i win-col? if drop -1 unloop ;then
  loop

  win-dia? if drop -1 ;then

  drop 0
;


| evaluates the current position.
| If the position is a decision (win for X or O or no more remaining moves)
| the stack is set as follows:
| -100 -1  : win for O
|  100 -1  : win for X
|    0 -1  : draw (no more moves)
|
| If the position is not yet an end position the stack looks like:
| 0
: eval-pos ( -- value endposition? | 0 )
  X win? if  100 -1 ;then
  O win? if -100 -1 ;then
  #moves 0if   0 -1 ;then

  0
;


: user-move ( -- )
  repeat
    cr ." Your move (1-9, q: quit)>" cr
    ekey dup 'q =if ." ok, bye" cr bye ;then
    '1 - board +
    dup c@ empty <> if drop ." illegal move!" cr true else currentPlayer @ swap c! false then
  while

  display
;


defer find-move


: eval-move ( m -- m value )
  dup

  | make the move
  board +  currentPlayer @  swap  c!  | m

  eval-pos
  if
    | It is an end position
    | current stack is: m value
  else
    | It is not an end position
    | Find the best contrahent's move in this position
    toggle-player

    find-move
    | m best-contrahent's-move best-contrahent's-move-value
    swap drop | m value

    toggle-player
  then

  | current stack: m value

  | takeback the move
  over board +  empty  swap  c!
;


:: ( -- best-move best-value )

  -1  | no move found until now...
  currentPlayer @
  'X =if
    -200  | X wants to maximize
  else
     200  | O wants to minimize
  then

  9 0do
    board i + c@ empty
    =if
      | Ok, move i is possible. Analyze it...
      i eval-move | best-move best-value current-move current-value
      rot         | best-move current-move current-value best-value

      2dup
      currentPlayer @
      'X =if
        >if    | X wants to maximize
          drop rot drop  | current-move current-value  (this move is the best until now)
        else
          nip nip
        then
      else
        <if    | O wants to minimize
          drop rot drop
        else
          nip nip
        then
      then

    then
  loop
; is find-move


: computer-move
  find-move

  move-value !

  | Make the move
  board + currentPlayer @ swap c!

  display
;


: play
  init
  toggle-player
  repeat
    toggle-player
    display
    currentPlayer @ 'X =if user-move else computer-move then

    eval-pos
    if
      dup  100 =if ." Win: X" cr then
      dup -100 =if ." Win: O" cr then
               0if ." Draw!"  cr then
      false
    else
      true
    then
  while
;

: go  play ;

go 
