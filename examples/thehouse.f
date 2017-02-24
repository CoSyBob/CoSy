| thehouse.f
|
| This example demonstrates how to work with small graphs
| and simple graph algorithms with Reva
|
| Author: Danny Reinhold / Reinhold Software Services
| Reva's license also applies to this file!

: infos
quote %
 This program calculates all solutions for the popular graph drawing problem.
 The house looks like this:
         N3
         /\
        /  \
       /    \
      /      \
     /        \
 N4 X----------X N2
    |\        /|
    | \      / |
    |  \    /  |
    |   \  /   |
    |    \/    |
    |    /\    |
    |   /  \   |
    |  /    \  |
    | /      \ |
    |/        \|
 N0 X----------X N1

%
type
;


: <>  = not ;

8 constant nof-edges
5 constant nof-nodes

nof-edges 1- constant last-edge
nof-nodes 1- constant last-node


: X, -1 1, ;
: _,  0 1, ;

| connection matrix
| =================
| The rows are the nodes of the graph.
| The columns are the edges.
create connections
  X, _, _, _, X, _, _, X,
  X, X, _, _, _, _, X, _,
  _, X, X, _, _, X, _, X,
  _, _, X, X, _, _, _, _,
  _, _, _, X, X, X, X, _,

create edge-data  nof-edges allot

variable nof-solutions
nof-edges 1+  stack: path

: show-path
  nof-solutions @ . ." . solution: "
  nof-edges 0  do  path pop dup ." N" . ." -> "  loop  path pop dup ." N" .
  nof-edges 1+  0  do  path push  loop
  cr
;


: visited  ( edgepos -- flagaddr ) edge-data +  ;
: visited! ( edgepos flag -- )     swap visited c! ;
: visited? ( edgepos -- flag )     visited c@  255  =  ;
: visit    ( edgepos -- )          -1 visited! ;
: unvisit  ( edgepos -- )          0 visited! ;
: connected? ( node edge -- flag )  swap  nof-edges *  connections +  +  c@  255 = ;
: solution? ( -- flag )  -1  nof-edges 0 do  i visited?  and  loop  ;

: other-node ( node edge -- othernode )
  nof-nodes 0  do  2dup  i swap connected?  swap i <>  and  if  2drop i leave  then  loop
;

: search ( node -- )
  dup
  path push

  nof-edges 0 do 
    dup i connected?  i visited? not  and
    if  i visit  dup i other-node  search  i unvisit  then
  loop

  solution?  if  1 nof-solutions +!  show-path  then

  path pop
  2drop
;


: house
  infos
  0 nof-solutions !
  nof-edges 0 do  i unvisit  loop

  nof-nodes 0 do  i search  loop

  cr ." Number of solutions: " nof-solutions @ . cr
;

house
