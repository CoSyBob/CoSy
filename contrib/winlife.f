alias: \ |
\ needs gtextras.f     \ my library of extras
needs asm            \ for inline assembly (requires fasm.exe in \reva directory)
needs alg/structs        \ for windows api structures
needs util/locals
needs util/case

\ Author Gtinker   10-Feb-2006
\ John Conway's Game of Life
\ see http://en.wikipedia.org/wiki/Conway%27s_Game_of_Life

\ Reva6.0 version for windows
\ modified for 6.0.1 by Ron


\ Handles for Windows functions

u32 drop  \ switch to USER lib
1 func:  RegisterClassA as RegisterClass
12 func:  CreateWindowExA as CreateWindow
2 func:  LoadIconA as LoadIcon
2 func:  LoadCursorA as LoadCursor
1 func:  PostQuitMessage
4 func:  DefWindowProcA as DefWindowProc
4 func:  GetMessageA as GetMessage
5 func:  PeekMessageA as PeekMessage
1 func:  TranslateMessage
1 func:  DispatchMessageA as DispatchMessage
2 func:  BeginPaint
2 func:  EndPaint
1 func:  GetDC
2 func:  ReleaseDC

k32 drop \ switch to KERNEL lib
1 func:  GetModuleHandleA as GetModuleHandle

g32 drop \ switch to GDI lib
5 func:  TextOutA as TextOut
1 func:  CreateSolidBrush
4 func:  SetPixel

\ Windows constants
32512 dup   constant IDI_APPLICATION
            constant IDC_ARROW
15          constant COLOR_BTNFACE
$010000000  constant WS_VISIBLE
$000080000  constant WS_SYSMENU
$0002       constant WM_DESTROY
$000040000  constant WS_THICKFRAME
$000F       constant WM_PAINT
$40000000   constant WS_CHILD
$01         constant BS_DEFPUSHBUTTON
$0111       constant WM_COMMAND
$01         constant PM_REMOVE
$00         constant PM_NOREMOVE
$20         constant CS_OWNDC

\ button IDs
1000 constant start-id
1001 constant clear-id
1002 constant hline-id
1003 constant vline-id
1004 constant square-id
1005 constant cross-id
1006 constant pentomino-id
1007 constant blocks-id
1008 constant sstep-id

560 constant height  \ 560 gets us about centered in the client area
560 constant width

variable hdc
variable hinst
variable hwnd
variable play
variable cellbuf    \ pointer to buffer of 'life' cells
variable savebuf
variable narray     \ pointer to array of neighbour counts
variable pcell
variable nn
variable colour

\ Constant strings:
: windowclass " reva_winapp" zt ;
: buttonclass " BUTTON" zt ;

\ Structure declarations
struct: PAINTSTRUCT
    long: ps_hdc
    long: ps_ferase
    long: ps_rcpaint.left
    long: ps_rcpaint.top
    long: ps_rcpaint.right
    long: ps_rcpaint.bottom
    long: ps_frestore
    long: ps_fincupdate
    32 field: ps_rgbreserved
struct;

struct: MSG
    long: ->hwnd
    long: ->msg
    long: ->wp
    long: ->lp
    long: ->time
    long: ->x
    long: ->y
struct;

struct: WNDCLASS
    long: ->style
    long: ->wndproc
    long: ->cbClassExtra
    long: ->cbWndExtra
    long: ->hInstance
    long: ->hIcon
    long: ->hCursor
    long: ->hbrBackground
    long: ->lpszMenuName
    long: ->lpszClassName
struct;

\ Structure variables
PAINTSTRUCT ps
MSG msg
WNDCLASS wc


0 constant nonassembler     \ 0 = use assembler for nloop and pixloop

\ count the neighbours of each cell
nonassembler [IF]
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
            width - dup ++
            1- dup ++
            2 + dup ++
            width + dup ++
            2 - dup ++
            width + dup ++
            1+ dup ++
            1+ ++
        then
      loop
  loop
  ;

[ELSE]
: nloop  \ assembler version
    0
    height 1- 1 do  \ avoid boundaries

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

[THEN]

nonassembler [IF]
: pixloop  \ set or clear a pixel depending on neighbour count
    height 1-  1  do     \ for each row of cells
 \      $0201 colour @ + $0ffffff and colour ! \ new colour
       i width * cellbuf @ + pcell !   \ address of this row of cells
       i width * narray @ + nn !       \ address of this row of neighbour counts
       width 1-  1  do               \ for each cell in a row
            pcell ++             \ bump cell address
            nn dup ++ @ c@ dup 3              \ get neighbour count, is it 3
            =if drop pcell @ c@      \ is cell off?
                 0if
                    1 pcell @  c!    \ turn it on
                    hdc @ i j $008fff8f SetPixel drop    \ draw pixel
                then
            else 2                   \ not three neighbours, is it also not two?
                <>if  pcell @  c@     \ if cell is on
                     if 0 pcell @  c! \ turn it off
                        hdc @ i j $0 SetPixel  drop  \ clear pixel
                     then
                then
            then
        loop
    loop
    ;
[ELSE]
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
                    mov EAX, 0x0080ff80 ; \ colour for SetPixel
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
[THEN]
\ reva register usage
\ EAX Top of stack
\ ESI Data stack
\ [ESI] Second item on stack,  4 [ESI] third item on stack, 8 [ESI] etc
\ ESP Return stack  (also push and pop stack pointer in assembler)
\ other registers are used but do not need to be preserved
\ so we have EBX, ECX, EDX, EBP, EDI to play with. As well as EAX if we don't need TOS


: pass   \ run a pass of life
    narray @ height width * 0 fill   \ clear the neighbour counts
    nloop \ scan the cells and count the neighbors
    pixloop \ now update the playfield according to new counts
    ;

\ Draw initial patterns in reponse to button presses
: pix   ( x y ) \ draw a pixel
    hdc @ rot rot $00ffffff SetPixel drop ;

: clear-field  \ clear all cells
    height 0 do
        width 0 do hdc @ i j 0 SetPixel drop loop   \ clear all pixels
    loop
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


\ do the button functions

' hline variable, startingpattern
: setpat ( xt -- )
     dup startingpattern !  execute ;

\ decode a button click
: decodebuttons { hwnd msg wparam lparam -- }
    wparam $ffff and      \ get button id from wparam
    case
        start-id of  play @ -1 xor play ! endof
        clear-id of  clear-field  endof
        hline-id of  ['] hline setpat endof
        vline-id of  ['] vline setpat endof
        square-id of ['] square setpat endof
        cross-id of ['] cross setpat endof
        pentomino-id of  ['] pentomino setpat endof
        blocks-id of ['] blocks setpat endof
        sstep-id of 1 play ! endof
    endcase
    ;


\ the Window procedure
::   ( hwnd uMsg wParam lParam )       \ we only need the XT for the callback, we don't need a name
    2 pick                                  \ get uMsg
    WM_PAINT =if                            \ process WM_PAINT message
        3 pick ps                           \ hwnd ps
        BeginPaint dup hdc !                 \ leaves HDC on stack
        650 10 " GAME OF LIFE" TextOut drop   \ write our message
        3 pick ps EndPaint ;;                 \ tell Windows we are done
    then
    2 pick WM_DESTROY =if 0 PostQuitMessage ;;  then
    2 pick WM_COMMAND =if  decodebuttons ;;  then
    DefWindowProc                   \ pass to default handler
    ; 4 20 cb: winproc              \ four parameters, give it a 20 deep stack

\ message loop:
: msgloop
    repeat
        msg 0 0 0 PM_NOREMOVE PeekMessage 0if 1 ;; then  \ return with 1 (no messages)
        msg 0 0 0 GetMessage 0if 0 ;; then    \ return with 0 (quit)
        msg TranslateMessage drop
        msg DispatchMessage drop
    again ;

: stagnant? ( -- n) \ compare cellbuf with savebuf, return 1 if identical
    width height * 0 do
        cellbuf @ i + c@
        savebuf @ i + c@
        <>if 0 rdrop rdrop ;; then
    loop
    1
    ;

: create-button { a n x y w h id -- }
    0 buttonclass
    a n zt
    WS_VISIBLE WS_CHILD or BS_DEFPUSHBUTTON or
    x y w h
    hwnd @
    id
    hinst @ 0 CreateWindow drop
    ;

\ The Main program
: go { | rctr -- }
    \ set up the window class
    0 GetModuleHandle dup hinst ! wc ->hInstance !
    0 IDI_APPLICATION LoadIcon wc ->hIcon !
    0 IDC_ARROW LoadCursor wc ->hCursor !
    ['] winproc wc ->wndproc !
    $00 CreateSolidBrush wc ->hbrBackground !    \ black background
    \ COLOR_BTNFACE 1 + wc ->hbrBackground !
    windowclass wc ->lpszClassName !
    CS_OWNDC wc ->style !   \ this gets a window with a private Device Context
    wc RegisterClass drop

    \ create main window
    0 windowclass " winlife" zt   \ class and title strings
    WS_VISIBLE WS_SYSMENU or WS_THICKFRAME or
    0 0 800 600
    0 0 hinst @ 0
    CreateWindow hwnd !

    \ create buttons
    " START" 670 40 60 25 start-id  create-button
    " CLEAR" 670 70 60 25 clear-id create-button
    " HLINE" 670 100 60 25 hline-id create-button
    " VLINE" 670 130 60 25 vline-id create-button
    " SQUARE" 670 160 60 25 square-id create-button
    " CROSS" 670 190 60 25 cross-id create-button
    " PENT" 670 220 60 25 pentomino-id create-button
    " BLOCKS" 670 250 60 25 blocks-id create-button
    " SSTEP" 670 280 60 25 sstep-id create-button

    height width * allocate cellbuf !   \ allocate the cell buffer memory
    cellbuf @ height width * 0 fill          \ clear it
    height width * allocate narray !   \ allocate the neighbour count mory
    narray @ height width * 0 fill          \ clear it
    height width * allocate savebuf !   \ allocate the save buffer memory

    \ we have specified a private Device Context, so we only need to get it once
    hwnd GetDC hdc !

    startingpattern @ execute   \ starting pattern
    -1 play !  \ set it playing
    0 to rctr

    \ the main loop
    repeat
        play @
        if
            play @ 1
            =if pass 0 play !   \ single step
            else

            pass

            then
        then
        msgloop     \ process windows messages, returns 0 on quit message
    while

    cellbuf @ free   \ free cell buffer
    narray @ free
    savebuf @ free
    bye
    ;

\ code to make executable: change '1' to '0' below:
1 [IF]
 go
[ELSE]
 ' go is appstart
 save winlife.exe
[THEN]



