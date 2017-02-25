\ This is freeware, copyright Gordon Charlton, 12th of September 1994.
\ Copy and distribute it. Use it. Don't mess with this file. Acknowledge 
\ its use. I make no guarentees as to its fitness for any purpose. Tell
\ me about any bugs. Tell me how much you like it.

\                               An ANS Heap

\ This is an implementation of the ANS Forth Memory-Allocation Word Set. 
\ This is an ANS standard program that has the following environmental 
\ dependency - two's complement arithmetic.  It requires four words 
\ from the core extension:   0> NIP TUCK \ 

\ (If you go to the trouble of checking these claims, please e-mail me 
\ with your findings; gordon@charlton.demon.co.uk)

\ There are five broad areas that the program covers;

\      1, General purpose extensions to the Forth system.

\      2, Creation of the heap and associated use of the data space.

\      3, Allocation of space from the heap.

\      4, Releasing space back to the heap.

\      5, Altering the size of allocated heap space.


\ The ANS word set consists of three words, ALLOCATE, FREE, and RESIZE 
\ which give the minimum functionality required to use the heap. These are 
\ given in areas 3, 4 and 5 respectively.

\ The heap is maintained as a doubly linked ordered circular list of nodes 
\ with an additional field noting the size of each node and whether it is in 
\ use. The size of the heap is specified by the constant HEAPSIZE. The 
\ constant HYSTERESIS controls the amount of spare space that is added to 
\ an allocation, to reduce the need for block moves during resizing.

\ Initially there is only one node, the size of the heap. Aditional nodes 
\ are created by dividing an existing node into two parts. Nodes are removed 
\ by marking as free, and merging with adjoining free nodes. Nodes are 
\ altered in size by merging with a following free node, if possible, and a 
\ node being created above the new size of the node, if needed, or by 
\ allocating a new node and block moving the data field if necessary.

\ Finding an available node is done by sequential search and comparison. The 
\ first node to be found that is large enough is used for allocation. Each 
\ search starts from the node most recently allocated, making this a 
\ "nextfit" algorithm. The redundancy in the head fields is required to 
\ optimise the search loop, as is the use of a sentinel to terminate the 
\ search once every node has been looked at, by always succeeding. A final 
\ refinement is the use of the sign bit of the size field to mark "in-use" 
\ nodes so that they are disregarded without a separate test. 


\ **1** General Purpose Extensions

: unique (  )  VARIABLE ;
\ 
\ Defining word. Each child returns a different non-zero number. The 
\ standard introduces the need for unique identifiers in the form of IORs 
\ and THROW codes, but provides no means for generating them. This does
\ the trick.

: k ( n--n)  1024 * ;
\ 
\ A convenient way of referring to large numbers. Multiplies a number by 
\ 1024.

0 1 2 UM/MOD NIP 1- CONSTANT maxpos
\ 
\ The largest positive single length integer.


\ **2** Heap Creation

\ ANSI Heap  ---  Constants

16 k CELLS CONSTANT heapsize
\ 
\ Number of address units of data space that the heap occupies.

4 CELLS 1- CONSTANT hysteresis
\ 
\ Node lengths are rounded up according to the value of HYSTERESIS to 
\ reduce the number of block moves during RESIZE operations. The value of 
\ this constant must be one less than a power of two and at least equal to 
\ one less than the size of a cell.

unique allocationerror
\ 
\ Indicates there is less contiguous heap space available than required.

3 CELLS CONSTANT headsize
\ 
\ A node on the heap consists of a three cell head followed by a variable 
\ length data space. The first cell in the head points to the next node in 
\ the heap. The second cell indicates the size of the node, and the third 
\ points to the previous node. The second cell is negated to indicate the 
\ node is in use. The heap consists of a doubly linked circular list. There 
\ is no special notation to indicate an empty list, as this situation 
\ cannot occur.

: adjustsize ( n--n)  headsize +  hysteresis OR  1+ ;
\ 
\ The amount of space that is requested for a node needs adjusting to 
\ include the length of the head, and to incorporate the hysteresis.

0 adjustsize CONSTANT overhead
\ 
\ The size of the smallest possible node.


\ ANSI Heap  ---  Structure

CREATE sentinel  HERE CELL+ ,   maxpos ,  0 ,  0 ,
\ 
\ A dummy node used to speed up searching the heap. The search, which is 
\ for a node larger than or equal to the specified size will always succeed. 
\ The cell that points to the next node is set up so that the there is a zero 
\ three cells ahead of where it points, where the pointer to the previous 
\ node (ie the sentinel) should be. This is a special value that indicates the 
\ search has failed.

CREATE heap  heapsize ALLOT
\ 
\ The heap is as described in HEADSIZE.

VARIABLE nextnode
\ 
\ Searching is done using a "nextfit" algorithm. NEXTNODE points to the 
\ most recently allocated node to indicate where the next search is to 
\ start from.

: >size ( addr--addr)  CELL+ ;
\ 
\ Move from the "next" cell in the node head to the "size" cell. Within the 
\ word set nodes are referred to by the address of the "next" cell. 
\ Externally they are referred to by the address of the start of the data 
\ field.

: >prev ( addr--addr)  2 CELLS + ;
\ 
\ Move from the "next" cell to the "previous" cell.

: init-heap (  )  heap DUP nextnode !  
                  DUP DUP !
                  DUP heapsize  OVER >size !  
                  >prev ! ;
\ 
\ Initially the heap contains only one node, which is the same size as the 
\ heap. Both the "next" cell and the "previous" cell point to the "next" 
\ cell, as does NEXTNODE.                  

init-heap

\ **3** Heap Allocation

\ ANSI Heap  ---  List Searching

: attach ( addr)  >prev @
                  DUP sentinel ROT !
                  sentinel >prev ! ;
\ 
\ The sentinel is joined into the nodelist. The "next" field of the node 
\ preceding the one specified (addr) is set to point to the sentinel, and 
\ the "prev" field of the sentinel to point to the node that points to the 
\ sentinel.

: search  ( addr size--addr|0)  
          >R BEGIN 2@ SWAP R@ < INVERT UNTIL
          R> DROP  >prev @ ;
\ 
\ Search the nodelist, starting at the node specified (addr), for a free 
\ node larger than or equal to the specified size. Return the address of the 
\ first node that matches, or zero for no match. The heap structure is set up 
\ to make this a near optimal search loop. The "size" field is next to the "next" 
\ field so that both can be collected in a single operation (2@). Nodes in 
\ use have negated sizes so they never match the search. The "previous" 
\ field is included to allow the search to overshoot the match by one node 
\ and then link back outside the loop, rather than remembering the address 
\ of the node just examined. The sentinel removes the need for a separate 
\ test for failure. SEARCH assumes the sentinel is in place.

: detach ( addr)  DUP >prev @ ! ;
\ 
\ Remake the link from the node prior to the one specified to the one 
\ specified. This will remove the sentinel if it is attached here. (It will 
\ be.)

: findspace ( size--addr|0)  nextnode @
                             DUP      attach
                             DUP ROT  search
                             SWAP     detach ;             
\ 
\ Search the nodelist for a node larger or equal to that specified. Return 
\ the address of a suitable node, or zero if none found. The search starts at 
\ the node pointed to by NEXTNODE, the sentinal temporarily attached, the 
\ search proceeded with and the sentinel detached. 


\ ANSI Heap  ---  Head Creation

: fits ( size addr--flag)  >size @ SWAP -  overhead  < ;
\ 
\ Returns TRUE if the size of the node specified is the same as the 
\ specified size, or larger than it by less than the size of the smallest 
\ possible node. Returns FALSE otherwise.

: togglesize ( addr)  >size DUP @  NEGATE SWAP ! ;
\ 
\ Negate the contents of the "size" field of the specified node. If the 
\ node was available it is marked as in use, and vice versa.

: next! ( addr)  nextnode ! ;
\ 
\ Make the specified node the starting node for future searches of the node 
\ list.

: sizes! ( size addr--addr)  2DUP + >R
                             >size 2DUP @ SWAP -
                             R@ >size !
                             SWAP NEGATE SWAP !  R> ;
\ 
\ Given a free node (addr), reduce its size to that specified and mark it 
\ as in use. Start to construct a new node within the specified node beyond 
\ its new length, by storing the length of the remainder of the node in the 
\ size field of the new node. Return the address of the partially 
\ constructed node.

: links! ( addr1 addr2)  2DUP SWAP @  2DUP  SWAP !  >prev !
                                      2DUP >prev !   SWAP ! ;

\ 
\ Addr1 is an existing node. Addr2 is the address of a new node just above 
\ the existing node. Break the links from the existing node to the next 
\ node and from the next node to the existing node and join the new node to 
\ them. 


\ ANSI heap  ---  Node Construction     ALLOCATE

: newnode ( size addr)  TUCK sizes!  links! ;
\ 
\ Given a free node at addr split it into an in-use node of the specified 
\ size and a new free node above the in-use node.

: makenode ( size addr)  2DUP fits IF  togglesize DROP
                                 ELSE  newnode  
                                 THEN ;
\ 
\ Given a free node at addr make an in-use node of the specified size 
\ and free the remainder, if there is any usable space left.

: ALLOCATE ( u--addr ior)
          DUP 0< IF  allocationerror
               ELSE  adjustsize
                     DUP findspace
                     DUP IF  DUP next!
                             TUCK makenode
                             headsize +  0
                       ELSE  DROP allocationerror
                       THEN
               THEN ;
\ 
\ Make an in-use node with a data field at least u address units long. 
\ Return the address of the data field and an ior of 0 to indicate success. 
\ If the space is not available return any old number and an ior equal to the 
\ constant ALLOCATIONERROR. The standard specifies that the argument to 
\ ALLOCATE is unsigned. As the implementation uses the sign bit of the size 
\ field for its own purposes any request for an amount of space greater 
\ than MAXPOS must fail. As this would be a request for half the 
\ addressable memory or more this is not unreasonable.

\ **4** Releasing Space 

\ ANSI heap  ---  Head Destruction

: mergesizes ( addr addr)
             >size @ SWAP >size +! ;
\ 
\ Make the size field of the node at addr1 equal to the sum of the sizes of 
\ the two specified nodes. In usage the node at addr2 will be the one 
\ immediately above addr1.

: mergelinks ( addr addr)
             @ 2DUP SWAP !
                   >prev ! ;
\ 
\ The node at addr2 is removed from the node list. As with MERGESIZES the 
\ node at addr2 will be immediately above that at addr1. Destroy the link 
\ from node1 to node2 and relink node1 to the node above node2. Destroy the 
\ backward link from the node above node2 and relink it to node1. 

: jiggle (  )
         nextnode @ @  >prev @  next! ;
\ 
\ There is a possibility when a node is removed from the node list that 
\ NEXTNODE may point to it. This is cured by making it point to the node 
\ prior to the one removed. We do not want to alter the pointer if it does 
\ not point to the removed node as that could be detrimental to the 
\ efficiency of the nextfit search algorithm. Rather than testing for this 
\ condition we jiggle the pointer about a bit to settle it into a linked 
\ node. This is done for reasons of programmer amusement. Specifically 
\ NEXTNODE is set to point to the node pointed to by the "previous" field 
\ of the node pointed to in the "next" field of the node pointed to by 
\ NEXTNODE. Ordinarily this is a no-op (ie I am my father's son) but when 
\ the node has had its links merged it sets NEXTNODE to point to the node 
\ prior to the node it pointed to (ie when I died my father adopted my son, 
\ so now my son is my father's son).

: merge ( addr)
        DUP @ 2DUP mergesizes
                   mergelinks  jiggle ;                   
\ 
\ Combine the node specified with the node above it. Merge the sizes, merge 
\ the lengths and jiggle.


\ ANSI Heap  ---  Node Removal          FREE

: ?merge ( addr1 addr2)  >size @
                         0> IF  DUP DUP @
                                U< IF  DUP merge
                                   THEN
                            THEN  DROP ;
\ 
\ Merge the node at addr1 with the one above it on two conditions, firstly 
\ that the node at addr2 is free, and secondly that the node pointed to by 
\ the next field in addr1 is actually above addr1 (ie that it does not wrap 
\ around because it is the topmost node). In usage addr2 will be either 
\ addr1 or the node above it. In each instance the other affected node 
\ (either the node above addr1 or addr1) is known to be free, so no test is 
\ needed for this.

: ?mergenext ( addr)  DUP @ ?merge ;
\ 
\ Merge the node following the specified node with the specified node, if 
\ following node is free.

: ?mergeprev ( addr)  >prev @ DUP ?merge ;
\ 
\ Merge the specified node with the one preceding it, if the preceding node 
\ is free.

: FREE ( addr--ior)  headsize -
                     DUP togglesize
                     DUP ?mergenext
                     ?mergeprev  0 ;                     
\ 
\ Mark the specified in-use word as free, and merge with any adjacent free 
\ space. As this is a standard word addr is the address of the data field 
\ rather than the "next" field. As there is no compelling reason for this 
\ to fail the ior is zero.


\ **5** Resizing Allocated Space

\ ANSI Heap  ---  Node Repairing

VARIABLE stash
\ 
\ The RESIZE algorithm is simplified and made faster by assuming that it 
\ will always succeed. STASH holds the minimum information required to make 
\ good when it fails.

: savelink ( addr)  @ stash ! ;
\ 
\ Saves the contents of the >NEXT field of the node being RESIZEd in STASH 
\ (above).

: restorelink ( addr)  stash @  SWAP ! ;
\ 
\ Converse operation to SAVELINK (above).

: fixprev ( addr)  DUP >prev @ ! ;
\ 
\ The >NEXT field of the node prior to the node being RESIZEd should point 
\ to the node being RESIZEd. It may very well do already, but this makes 
\ sure. 

: fixnext ( addr)  DUP @ >prev ! ;
\ 
\ The >PREV field of the node after the node resized may need correcting. 
\ This corrects it whether it needs it or not. (Its quicker just to do it 
\ than to check first.)

: fixlinks ( addr)  DUP fixprev  DUP fixnext  @ fixnext ;
\ 
\ RESIZE may very well merge its argument node with the previous one. It 
\ may very well merge that with the next one. This means we need to fix the 
\ previous one, the next one and the one after next. To extend the metaphor 
\ started in the description of JIGGLE (above), not only did I die, but my 
\ father did too. This brings my grandfather into the picture as guardian 
\ of my son. Now to confound things we have all come back to life. I still 
\ remember who my son is, and my father remembers who his father is. Once I 
\ know who my father is I can tell my son that I am his father, I can tell 
\ my father that I am his son and my grandfather who his son is. Thankfully 
\ we are only concerned about the male lineage here! (In fact nodes 
\ reproduce by division, like amoebae, which is where the metaphor breaks 
\ down -- (1) they are sexless and (2) which half is parent and which 
\ child?)

: fixsize ( addr)  DUP >size @ 0>
                   IF  DUP @  2DUP <
                       IF  OVER - SWAP >size !
                     ELSE 2DROP
                     THEN
                 ELSE  DROP
                 THEN ;
\ 
\ Reconstruct the size field of a node from the address of the head and the 
\ contents of the >NEXT field provided that the node is free and it is not 
\ the topmost node in the heap (ie there is no wraparound). Both these 
\ conditions need to be true for the node to have been merged with its 
\ successor.

: fixsizes ( addr)  DUP fixsize  >prev @ fixsize ;
\ 
\ The two nodes whose size fields may need repairing are the one passed as 
\ an argument to RESIZE (damaged by ?MERGENEXT) and its predecessor 
\ (damaged by ?MERGEPREV).

: repair ( addr)  DUP restorelink
                  DUP fixlinks  DUP fixsizes
                  togglesize ;                  
\ 
\ Make good the damage done by RESIZE. Restore the >next field, fix the 
\ links, fix the size fields and mark the node as in-use. Note that this 
\ may not restore the system to exactly how it was. In particular the pointer
\ NEXTNODE may have moved back one or two nodes by virtue of having been 
\ JIGGLEd about if it happened to be pointing to the wrong node. This is not 
\ serious, so I have chosen to ignore it.


\ ANSI Heap  ---  Node Movement

: toobig? ( addr size--flag)
          SWAP  >size @  > ;
\ 
\ Flag is true if the node at addr is smaller than the specified size.

: copynode ( addr1 addr2)
       OVER >size @  headsize -
       ROT  headsize + ROT ROT MOVE ;
\ 
\ Move the contents of the data field of the node at addr1 to the data 
\ field at addr2. Assumes addr2 is large enough. It will be.

: enlarge ( addr1 size--addr2 ior)
          OVER  ?mergeprev
          ALLOCATE DUP >R
          IF  SWAP repair
        ELSE  TUCK copynode
        THEN R> ;        
\ 
\ Make a new node of the size specified. Copy the data field of addr1 to 
\ the new node. Merge the node at addr1 with the one preceding it, if 
\ possible. This last behaviour is to finish off removing the node at 
\ addr1. The word ADJUST (below) starts removing the node. The node is 
\ removed before allocation to increase the probability of ALLOCATE 
\ succeeding. The address returned by ENLARGE is that returned by ALLOCATE, 
\ which is that of the data field, not the head. If the allocation fails 
\ repair the damage done by removing the node at addr1.


\ ANSI Heap  ---  Node Restructuring    RESIZE

: adjust ( addr1 size1--addr2 size2)  adjustsize >R
                                      headsize -
                                      DUP savelink
                                      DUP togglesize
                                      DUP ?mergenext R> ;
\ 
\ Addr1 points to the data field of a node, not the "next" field. This 
\ needs correcting. Size1 also needs adjusting as per ADJUSTSIZE. In 
\ addition it is easier to work with free nodes than live ones as the size 
\ field is correct, and, as we intend to change the nodes size we will 
\ inevitably want to muck about with the next node, if its free, so lets 
\ merge with it straight away. Sufficient information is first saved to put 
\ the heap back as it was, if necessary. Now we are ready to get down to 
\ business.

: RESIZE ( addr1 u--addr2 ior)
         DUP 0< IF  DROP allocationerror
              ELSE  adjust  2DUP
                    toobig?  IF  enlarge
                           ELSE  OVER makenode
                                 headsize +  0
                           THEN
              THEN ;
\ 
\ Resize the node at addr1 to the specified size. Return the address of the 
\ resized node (addr2) along with an ior of zero if successful and 
\ ALLOCATIONERROR if not. Addr2 may be the same as, or different to, addr1. 
\ If ior is non-zero then addr2 is not meaningful. Being a standard word 
\ the arguments need adjusting to the internal representation on entry, and 
\ back again on exit. If after the first merge the requested size is still 
\ too large to reuse the specified node then it is moved to a larger node 
\ and the specified node released. If, on the other hand the request is not 
\ too big for the node, then we remake the node at the right length, and 
\ free any space at the top using MAKENODE, which has just the right 
\ functionality. In this case the ior is zero. As this is a standard word it 
\ takes an unsigned size argument, but excessive requests fail 
\ automatically, as with ALLOCATE.
