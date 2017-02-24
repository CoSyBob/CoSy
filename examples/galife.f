alias: \ |        \ I like to use '\' for comments
needs asm       \ for inline assembly routines pixloop and nloop (requires fasm in \reva directory)
needs callbacks


\ Author Gtinker   5-April-2006
\ John Conway's Game of Life
\ see http://en.wikipedia.org/wiki/Conway%27s_Game_of_Life
\ Reva6.04 version for GraphApp gui  see http://enchantia.com/software/graphapp/

\ load the GraphApp lib
os [IF] " libapp.so" [ELSE] " graphapp.dll" [THEN] lib GA

\ Declare GraphApp functions
2 func: app_new_app as GAnewapp
7 func: app_new_window  as  GAnewwindow
1 func: app_show_window  as  GAshowwindow
1 func: app_main_loop  as  GAmainloop
1 func: app_wait_event  as  GAwaitevent
1 func: app_do_event  as  GAdoevent
0 func: app_new_rect as GAnewrect	\ can't get this to work!!!!
1 func: app_get_window_graphics  as  GAgetwindowg	
1 func: app_del_graphics  as  GAdelg
5 func: app_draw_line  as  GAdrawline     \ can't get this to work!!!
3 func: app_draw_point  as  GAdrawpoint
1 func: app_draw_all as GAdrawall
2 func: app_set_rgb as GAsetrgb
2 func: app_on_window_redraw as GAonwindowredraw
7 func: app_new_label as GAnewlabel
7 func: app_new_button as GAnewbutton
2 func: app_on_window_close as GAonwindowclose

 $20 $40 $80 $100 $200 or or or or value standard_window
0 value myGAapp	\ ptr to GraphApp application
0 value myGAwindow	\ ptr to GraphApp window
0 value mywg	\ window graphics object
0 value mylabel-c
1 value run

\ button IDs
0 value start-id
0 value clear-id
0 value hline-id
0 value vline-id
0 value square-id
0 value cross-id
0 value pent-id
0 value blocks-id
0 value sstep-id
0 value quit-id

560 value height  \ 560 gets us about centered in the client area
560 value width

variable play
variable cellbuf    \ pointer to buffer of 'life' cells
variable narray     \ pointer to array of neighbour counts
variable pcell
variable colour
variable hdc		\ just for compatibility - garbage in this version

: SetPixel ( hdc x y colour -- )    \ note hdc is just garbage
    mywg swap GAsetrgb drop	\ set colour
    mywg -rot  GAdrawpoint drop  \ draw pixel
    ;	   

: nloop  \ assembler version of neighbour counting loop
    0
    height 1- 1   \ avoid boundaries
    do
        \ stack up the parameters for the assembly code
        width  i * cellbuf @ +    \ [ESI+12] address of this row of cells
        width i * narray @ +      \ [ESI+8]  address of this row of neighbour counts
        width 1-                  \ [ESI+4]  loop limit
        1                         \ [ESI]    loop count
        0                         \ EAX      garbage to free EAX

        asm{
            mov ECX, [ESI+4]    ; \ get loop limit
            dec ECX
            .L0:
            inc dword [ESI+12]  ; \ bump cell ptr
            inc dword [ESI+8]   ; \ bump neighbour counts ptr
            mov EAX, [ESI+12]   ; \ get cell ptr
            mov AL, [EAX]       ; \ get cell
            or AL, AL           ; \ test it
            jz .L1              ; \ zero
                mov EAX, [ESI+8]    ; \ get nptr
                mov EBX, [ESI+4]    ; \ get width-1
                inc byte [EAX-1]    ; \ bump left nctr
                inc byte [EAX+1]    ; \ bump right nctr
                inc byte [EAX+EBX]   ; \ bump low left nctr
                inc byte [EAX+EBX+1] ; \ bump low nctr
                inc byte [EAX+EBX+2] ; \ bump low right nctr
                neg EBX
                inc byte [EAX+EBX]  ; \ bump top right nctr
                inc byte [EAX+EBX-1] ; \ bump top nctr
                inc byte [EAX+EBX-2] ; \ bump top left nctr

            .L1:
            dec ECX     ; \ done?
            jne .L0
            add ESI, 20 ; \ restore stack
            }
    loop
    drop
    ;

: pixloop  \ assembler version. Set or clear a pixel depending on neighbour count
    0
    height 1-  1  do     \ for each row of cells
        \ stack all parameters needed by assembler code
        ['] SetPixel            \ [ESI+24] address of SetPixel
        i width * cellbuf @ +   \ [ESI+20] address of this row of cells - pcell
        i width * narray @ +    \ [ESI+16] address of this row of neighbour counts - nn
        i                       \ [ESI+12]  row - j
        hdc @                   \ [ESI+8]  device context handle for SetPixel - hdc
        width 1 -               \ [ESI+4]  loop limit
        1                       \ [ESI]    loop start
        0                       \ EAX      garbage to keep EAX free
        asm{
            .L0:
            inc dword [ESI+20]    ; \ pcell ++
            inc dword [ESI+16]    ; \ nn ++
            mov EBX, [ESI+16]
            cmp byte [EBX], 3     ; \ 3 neighbours?
            jne .L1             ; \ no
                mov EBX, [ESI+20]   ; \ yes, get pcell
                cmp byte [EBX], 0
                jnz .L2             ; \ no
                    inc byte [EBX]       ; \ turn on this cell
                    mov EAX, [ESI+8]    ; \ get hdc
                    mov [ESI-4], EAX    ; \ stack it for SetPixel
                    mov EAX, [ESI]      ; \ get x
                    mov [ESI-8], EAX    ; \ stack it for SetPixel
                    mov EAX, [ESI+12]    ; \ get y
                    mov [ESI-12], EAX   ; \ stack it for SetPixel
                    mov EAX, 0x80ff8000 ; \ colour for SetPixel
                    mov EBX, [ESI+24]   ; \ address of SetPixel
                    sub ESI, 12         ; \ adjust tos ptr for call to SetPixel
                    call EBX            ; \ call SetPixel
                ;    add ESI, 4          ; \ drop
                    jmp .L2
            .L1:
            cmp byte [EBX], 2   ; \ 2 neighbours
            je  .L2       ; \ yes
                mov EBX, [ESI+20]    ; \ no, get pcell
                cmp byte [EBX], 0
                jz .L2            ; \ no
                    dec byte [EBX]      ; \ yes, turn off this cell
                    mov EAX, [ESI+8]    ; \ get hdc
                    mov [ESI-4], EAX    ; \ stack it for SetPixel
                    mov EAX, [ESI]      ; \ get x
                    mov [ESI-8], EAX    ; \ stack it for SetPixel
                    mov EAX, [ESI+12]   ; \ get y
                    mov [ESI-12], EAX   ; \ stack it for SetPixel
                    mov EAX, 0          ; \ colour for SetPixel
                    mov EBX, [ESI+24]   ; \ address of SetPixel
                    sub ESI, 12         ; \ adjust tos ptr for call to SetPixel
                    call EBX            ; \ call SetPixel
                 ;   add ESI, 4          ; \ drop
            .L2:
            inc dword [ESI]             ; \ bump loop ctr
            mov EAX, [ESI+4]      ; \ get limit
            cmp EAX, [ESI]        ; \ test for equal
            jne .L0
            add ESI, 32 ; \ restore stack
            }
    loop
    drop
    ;

: pass   \ run a pass of life
    narray @ height width * 0 fill   \ clear the neighbour counts
    nloop \ scan the cells and count the neighbors
    pixloop \ now update the playfield according to new counts
    ;

\ Draw initial patterns in reponse to button presses
: pix   ( x y -- ) \ draw a pixel
    hdc @ rot rot $ffffff00 SetPixel drop ;

: clear-field  \ clear all cells
    height 0 do
        width 0 do hdc @ i j 0 SetPixel drop loop   \ clear all pixels
    loop
    cellbuf @ height width * 0 fill \ clear the cell buffer
	;         

: hline            \ draw a horizontal line
    width 3 4 */     \ to 75% of width
    width 4 /        \ from 25% of width
    do
        i height 2 / pix  \ draw pixels
        1 width height 2 / *  i + cellbuf @ + c!  \ set the corresponding cells
    loop    
	;

: vline
    height 3 4 */     \ to 75% of height
    height 4 /        \ from 25% of height
    do
        width 2 / i pix \ draw pixels
        1  i  width * width 2 / + cellbuf @ + c!  \ set the corresponding cells
    loop    
	;  

: square
    width 3 4 */  width 4 /
    do i height 4 / pix    1 width height  4 / * i + cellbuf @ + c!    loop      \ draw top
    width 3 4 */  width 4 /
    do i height 3 4 */ pix  1 width height  3 4 */ * i + cellbuf @ + c!  loop   \ draw bottom
    height 3 4 */  height 4 /
    do width 4 / i pix   1  i width * width 4 /  + cellbuf @ + c!   loop      \ draw left side
    height 3 4 */ 1+ height 4 /
    do width 3 4 */ i pix  1  i width * width 3 4 */ + cellbuf @ + c! loop  \ draw right side
	;  

: cross
    height 3 4 */ 1+
    height 4 /
    do i i pix
       1  i width *  i + cellbuf @ + c!
       i height i - pix
       1  height i - width * i + cellbuf @ + c!
    loop    
    ;

: pentomino
    width 2 /  height 2 / 1-  pix  1 height 2 / 1-  width *      width 2 / + cellbuf @ + c!
    width 2 / 1-   height 2 / pix  1 height 2 / width *          width 2 / 1- + cellbuf @ + c!
    width 2 / height 2 / pix  1 height 2 /  width *              width 2 / + cellbuf @ + c!
    width 2 / height 2 / 1+ pix  1 height 2 / 1+  width *        width 2 / + cellbuf @ + c!
    width 2 / 1+  height 2 / 1+  pix  1 height 2 / 1 +  width *  width 2 / 1+  + cellbuf @ + c! 
    ;

: setcell ( x y -- )    \ set pixel and cell at x, y
    over over pix   \ draw the pixel
    width * + cellbuf @ + 1 swap c!
    ;

: blocks
    width 2 / height 2 /      \ get centre
    over 1 + over 2 - setcell
    over 2 + over 2 - setcell
    over 3 + over 2 - setcell
    over 1 + over 1 - setcell
    over 2 + over 1 - setcell
    over 3 + over 1 - setcell
    over 1 + over 0 - setcell
    over 2 + over 0 - setcell
    over 3 + over 0 - setcell

    over 2 - over 1 + setcell
    over 1 - over 1 + setcell
    over 0 - over 1 + setcell
    over 2 - over 2 + setcell
    over 1 - over 2 + setcell
    over 0 - over 2 + setcell
    over 2 - over 3 + setcell
    over 1 - over 3 + setcell
    over 0 - over 3 + setcell
    2drop
    ;

' hline variable, startingpattern
: setpat ( xt -- )
    dup startingpattern !  execute ;

\ button click handlers
::	( buttonptr -- )  0 cb-param play @ -1 xor play !	; 10 cb: start-cb
::	( buttonptr -- )  0 cb-param clear-field  	; 10 cb: clear-cb
::	( buttonptr -- )  0 cb-param ['] hline setpat 	; 10 cb: hline-cb
::	( buttonptr -- )  0 cb-param ['] vline setpat 	; 10 cb: vline-cb
::	( buttonptr -- )  0 cb-param ['] square setpat 	; 10 cb: square-cb
::	( buttonptr -- )  0 cb-param ['] cross setpat 	; 10 cb: cross-cb
::	( buttonptr -- )  0 cb-param ['] pentomino setpat 	; 10 cb: pent-cb
::	( buttonptr -- )  0 cb-param ['] blocks setpat 	; 20 cb: blocks-cb
::	( buttonptr -- )  1 play !	; 10 cb: sstep-cb
::	( buttonptr -- )  0 to run	; 10 cb: quit-cb

\ window close handler
::    (  window   -- )  0 to run ; 10 cb: close-cb


\ The Main program
: go 
    0 0 GAnewapp  to myGAapp	 	\ get a GrapApp application

    myGAapp 20 50  800 600 z" GAlife" standard_window GAnewwindow to myGAwindow	\ create window

    myGAwindow GAgetwindowg to mywg	\ get the window graphics object (needed for other functions)

     myGAwindow 650 20 90 30 z" Game of Life" 0 GAnewlabel	to mylabel-c \ add a label

    myGAwindow  ['] close-cb GAonwindowclose     \ setup the closewindow callback
    
    myGAwindow 670 40 65 25  z" START" [']  start-cb GAnewbutton	to start-id \ add a button
    myGAwindow 670 70 65 25  z" CLEAR" [']  clear-cb GAnewbutton to clear-id \ add a button
    myGAwindow 670 100 65 25  z" HLINE" [']  hline-cb GAnewbutton to hline-id \ add a button
    myGAwindow 670 130 65 25  z" VLINE" [']  vline-cb GAnewbutton to vline-id \ add a button
    myGAwindow 670 160 65 25  z" SQUARE" [']  square-cb GAnewbutton to square-id \ add a button
    myGAwindow 670 190 65 25  z" CROSS" [']  cross-cb GAnewbutton to cross-id \ add a button
    myGAwindow 670 220 65 25  z" PENT" [']  pent-cb GAnewbutton	to pent-id \ add a button
    myGAwindow 670 250 65 25  z" BLOCKS" [']  blocks-cb GAnewbutton to blocks-id \ add a button
    myGAwindow 670 280 65 25  z" SSTEP" [']  sstep-cb GAnewbutton to sstep-id \ add a button
    myGAwindow 670 340 65 25  z" QUIT" [']  quit-cb GAnewbutton to quit-id \ add a button

    myGAwindow  GAshowwindow  drop \ show the window
 
    height width * allocate cellbuf !   \ allocate the cell buffer memory
    cellbuf @ height width * 0 fill          \ clear it
    height width * allocate narray !   \ allocate the neighbour count mory
    narray @ height width * 0 fill          \ clear it

    repeat myGAapp GAdoevent while  \ process window events (seems to need this prior to drawing)
    clear-field 
    startingpattern @ execute   \ setup a starting pattern
 
    -1 play !  \ start in continuous mode
 
    \ the main loop
    repeat
		myGAapp GAdoevent drop	\ process window events
		play @
		if
			play @ 1
			=if pass 0 play !   \ single step
			else pass              \ continuous
			then
		then
		run
    while

    cellbuf @ free   \ free cell buffer
    narray @ free
    bye
    ;

go
