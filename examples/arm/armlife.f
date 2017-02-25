alias: \ |
with~ ~sys

\ ARM TEST APPLICATION 
| 13-Feb-08 Modified by gtinker to replace 'caseof' with 'of' to conform to reva7.0.5.

1 constant arm    \ set to nonzero to generate an arm executable, zero to run on desktop
needs arm/armwinhdr


\ windows structures
PAINTSTRUCT ps
WNDCLASS wc
MSG msg
RECT rec
variable myhwnd
variable hdc

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ LIFE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ button IDs
1000 constant quit-id
1001 constant hline-id
1002 constant vline-id
1003 constant square-id
1004 constant cross-id
1005 constant pento-id
1006 constant clear-id

240 constant height  \ 560 gets us about centered in the client area
240 constant width

variable play
variable cellbuf    \ pointer to buffer of 'life' cells
variable narray     \ pointer to array of neighbour counts
variable pcell
variable nn
variable colour
variable lfunc
\ 0 value lfunc

: c++ ( addr -- )	dup c@ 1+ swap c! ; \ increment the byte at addr

\ count the neighbours of each cell
: nloop
  height 1- 1 do  \ avoid boundaries
     width  i * cellbuf @ + pcell !     \ address of this cell
     width i * narray @ + nn !  \ n is current pointer into neighbour array
     width 1-  1 do \ for one row of pixels
        \ look at each cell and if set,
        \ bump each of its 8 neighbour counters
        i  pcell @ + c@  \ get cell
        if  \ bump the neighbour counters
            nn @ i +
            width - dup c++
            1- dup c++
            2 + dup c++
            width + dup c++
            2 - dup c++
            width + dup c++
            1+ dup c++
            1+ c++
        then
      loop
  loop
;


: pixloop  \ set or clear a pixel depending on neighbour count
    height 1-  1  do     \ for each row of cells
       $30201 colour @ + $0ffffff and colour ! \ new colour
       i width * cellbuf @ + pcell !   \ address of this row of cells
       i width * narray @ + nn !       \ address of this row of neighbour counts
       width 1-  1  do               \ for each cell in a row
            pcell ++             \ bump cell address
            nn dup ++ @ c@ dup 3              \ get neighbour count, is it 3
            =if drop pcell @ c@      \ is cell off?
                 0if
                    1 pcell @  c!    \ turn it on
                    hdc @ i j colour @ SetPixel drop    \ draw pixel
                then
            else 2                   \ not three neighbours, is it also not two?
                <>if pcell @  c@     \ if cell is on
                     if 0 pcell @  c! \ turn it off
                        hdc @ i j 0 SetPixel  drop  \ clear pixel
                     then
                then
            then
        loop
    loop
    ;

: pass   \ run a pass of life
    narray @ height width * 0 fill   \ clear the neighbour counts
    nloop \ scan the cells and count the neighbors
    pixloop \ now update the playfield according to new counts
    ;

\ draw initial patterns in reponse to button presses
: pix   ( x y ) \ draw a pixel
    hdc @ rot rot $00ffffff SetPixel drop ;

: clear-field  \ clear all cells
   0 rec ->left ! 0 rec ->top ! width rec ->right ! height rec ->bottom !
   hdc @ rec $000000 CreateSolidBrush FillRect drop
   cellbuf @ height width * 0 fill ;         \ clear the cell buffer

: hline            \ draw a horizontal line
    width 3 4 */     \ to 75% of width
    width 4 /        \ from 25% of width
    do
        i height 2 / pix  \ draw pixels
        1 width height 2 / *  i + cellbuf @ + c!  \ set the corresponding cells
    loop ;

: vline
   height 3 4 */     \ to 75% of height
   height 4 /        \ from 25% of height
   do
      width 2 / i pix
      1  i  width * width 2 / + cellbuf @ + c!  \ set the corresponding cells
   loop ;  \ draw pixels

: square
   width 3 4 */  width 4 /
   do i height 4 / pix    1 width height  4 / * i + cellbuf @ + c!    loop      \ draw top
   width 3 4 */  width 4 /
   do i height 3 4 */ pix  1 width height  3 4 */ * i + cellbuf @ + c!  loop   \ draw bottom
   height 3 4 */  height 4 /
   do width 4 / i pix   1  i width * width 4 /  + cellbuf @ + c!   loop      \ draw left side
   height 3 4 */ 1+ height 4 /
   do width 3 4 */ i pix  1  i width * width 3 4 */ + cellbuf @ + c! loop ;  \ draw right side

: cross
   height 3 4 */ 1+
   height 4 /
   do i i pix
      1  i width *  i + cellbuf @ + c!
      i height i - pix
      1  height i - width * i + cellbuf @ + c!
   loop ;

: pentomino
   width 2 /  height 2 / 1-  pix  1 height 2 / 1-  width *      width 2 / + cellbuf @ + c!
   width 2 / 1-   height 2 / pix  1 height 2 / width *          width 2 / 1- + cellbuf @ + c!
   width 2 / height 2 / pix  1 height 2 /  width *              width 2 / + cellbuf @ + c!
   width 2 / height 2 / 1+ pix  1 height 2 / 1+  width *        width 2 / + cellbuf @ + c!
   width 2 / 1+  height 2 / 1+  pix  1 height 2 / 1 +  width *  width 2 / 1+  + cellbuf @ + c! ;




: buttonpush ( hwnd uMsg wParam lParam -- )
   over case
      quit-id of 0 PostQuitMessage drop endof 
      lfunc !   \ save the button id to indicate next function to be performed
  endcase
   
;

: lifefunc
   lfunc @ case 
      0 of pass endof \ do a pass of life
      hline-id  of hline endof         
      vline-id of vline endof         
      square-id of square endof         
      cross-id of cross endof         
      pento-id of pentomino endof         
      clear-id of clear-field endof
   endcase
 	0 lfunc ! 
;

 
\ The window procedure  (parameters are on the system stack - accessed with cb-param)
:: 
   \ use of cb-param is currently restricted. It must be used prior to changing the system (return)
   \ stack. So eg it won't work inside a do loop, or in a called word (unless you adjust the param #)

   0 cb-param  1 cb-param  2 cb-param  3 cb-param  ( -- hwnd uMsg wParam lParam ) \ get the params
 	2 pick case                             \ get uMsg
		WM_PAINT of                            \ process WM_PAINT message
       	3 pick ps BeginPaint hdc !          	\ get a Device Context for drawing
			\ The WM_PAINT message is issued whenever the window needs to be redrawn so
			\ insert code here to do any custom drawing in the window
         lifefunc
         3 pick ps EndPaint drop                \ tell Windows we are done
   	0 endof 
    	WM_COMMAND of
          $0 beep drop buttonpush		\ go decode button push
      0 endof

      \ the default case
      drop  \ drop uMsg
      DefWindowProc  \ call the default message handler
   endcase
; 60 cb: winproc  \ make this word into a callback named winproc with a 60 deep stack  

: msgloop   \ message loop
	repeat
   	msg 0 0 0 0 PeekMessage 0if 1 ;; then  \ return 1 (no messages)
      msg 0 0 0 GetMessage 0if 0 ;; then     \ return 0 if quit message
      msg TranslateMessage drop
      msg DispatchMessage drop	\ send message to the Window Procedure.
   again
;


: create-button ( a x y w h id -- )
   >r >r >r >r >r >r
   0 zu" BUTTON"
   r>          \ name
   WS_VISIBLE WS_CHILD or BS_PUSHBUTTON or
   r> r> r> r> \ x y w h
   myhwnd @
   r>          \ id
   0  GetModuleHandle 0 CreateWindowEx drop
;



\ This is the highest level application word
: go    
   ffisetup \ setup the Foreign Function Interface to enable winapi functions (in armwinhdr.f) 

   \ fill in wc (a WNDCLASS struct)
   8                          wc ->style !   \ style - DBL_CLKS
   ['] winproc                wc ->wndproc !    
   0                          wc ->cbClassExtra !              
   0                          wc ->cbWndExtra !             
   0 GetModuleHandle          wc ->hInstance !  
   0                          wc ->hIcon !             
   0 ( $7F00 loadcursor)      wc ->hCursor !             
   $000000 CreateSolidBrush   wc ->hbrBackground !         
   0                          wc ->lpszMenuName !             
   zu" mywinclass"            wc ->lpszClassName ! 

   \ register it
   wc RegisterClass drop      \ should return nonzero (but we can drop it)  

   \ now create the window 
   0                       \ dwExStyle
   zu" mywinclass"      \ ClassName
   zu" LIFE"        \ Title
   WS_VISIBLE WS_SYSMENU or \ WS_CAPTION or WS_BORDER or
   0  26                    \ left, top
   240  320 \ 293                 \ width, height
   0                       \ parent
   0                       \ HMenu
   0 GetModuleHandle       \ hinstance
   0                       \ lpParam
   CreateWindowEx myhwnd !

   zu" clear" 5 270 43 20 clear-id  create-button
   zu" quit" 50 270 43 20 quit-id  create-button
   zu" hline" 5 245 43 20 hline-id  create-button
   zu" vline" 50 245 43 20 vline-id  create-button
   zu" box" 95 245 43 20 square-id  create-button
   zu" cross" 140 245 43 20 cross-id  create-button
   zu" pento" 185 245 43 20 pento-id  create-button

   height width * allocate cellbuf !   \ allocate the cell buffer memory
   cellbuf @ height width * 0 fill          \ clear it
   height width * allocate narray !   \ allocate the neighbour count mory
   narray @ height width * 0 fill          \ clear it

	hline		\ starting pattern
   -1 play !  \ set it playing12
   0 lfunc !   \ set pass function

   repeat  myhwnd @ 0 0 InvalidateRect drop msgloop while   \ InvalidateRect causes WM_PAINT msg
   bye
; 


\ End of arm application code

\ if arm is defined, make the arm exe image, otherwise run the application on the desktop
[DEFINED] arm [IF] ' go   here  makearmapp [ELSE] go [THEN]   

bye

