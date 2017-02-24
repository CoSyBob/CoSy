| RetroChess by Charles Childers
| Inspired by c4thches3 by Ray St. Marie
|
| This is a quick and dirty port. It could probably be cleaned up
| quite a bit. (And the style of the code is more retroforth-like,
| not using deferred words or such)
|
| Type "chess" <enter> to start the game
| Type "place <row,column> <row,column>" to move a piece
| Type "restart" to reset the board and start a new game
|
| We assume that you know the rules. It's two player. Enjoy!


defer place
defer chess
defer restart

loc:
  : >number prior >number drop ;
  |
  : later r> r> swap >r >r ;

  create blank
  'r 1, 'n 1, 'b 1, 'q 1, 'k 1, 'b 1, 'n 1, 'r 1,
  'p 1, 'p 1, 'p 1, 'p 1, 'p 1, 'p 1, 'p 1, 'p 1,
  '. 1, '. 1, '. 1, '. 1, '. 1, '. 1, '. 1, '. 1,
  '. 1, '. 1, '. 1, '. 1, '. 1, '. 1, '. 1, '. 1,
  '. 1, '. 1, '. 1, '. 1, '. 1, '. 1, '. 1, '. 1,
  '. 1, '. 1, '. 1, '. 1, '. 1, '. 1, '. 1, '. 1,
  'P 1, 'P 1, 'P 1, 'P 1, 'P 1, 'P 1, 'P 1, 'P 1,
  'R 1, 'N 1, 'B 1, 'Q 1, 'K 1, 'B 1, 'N 1, 'R 1,

  create board 64 allot

  :: blank board 64 move ; is restart
  restart

  defer display
  loc:
    variable line#
    : #|...| line# @ . '| emit space later '| emit cr line# dup ++ ;
    : ### ."     0 1 2 3 4 5 6 7" cr ;
    : --- ."    -----------------" cr ;
    : row 8 0 do dup c@ emit space 1+ loop ;
    : .row #|...| row ;
    :: 0 line# ! cr ### --- board 8 0 do .row drop loop drop --- cr ; is display
  loc;

  loc:
    : r,c ', parse >number parsews >number swap ;
    : pos r,c 8 * board + + ;
    :: pos dup c@ >r '. swap c! r> pos c! display ; is place
  loc;

   :: cr ." RetroChess for Reva" cr display ; is chess
loc;

| Type "chess" <enter> to start the game
." Type \"place <row,column> <row,column>\" to move a piece" cr
." Type \"restart\" to reset the board and start a new game" cr
chess
