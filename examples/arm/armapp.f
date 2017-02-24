alias: \ |
with~ ~sys

\ ARM EXAMPLE APPLICATION  - "HELLO WORLD"
| 13-Feb-08 Modified by gtinker to replace 'caseof' with 'of' to conform to reva7.0.5.

\ define 'arm' to generate an arm executable.  
\ If 'arm' is not defined, the app will run on the desktop
1 constant arm
needs arm/armwinhdr


\ windows structures
PAINTSTRUCT ps
WNDCLASS wc
MSG msg
variable mywinhandle
variable hdc
\ The window procedure  (parameters are on the system stack - accessed with cb-param)
:: 
   \ use of cb-param is currently restricted. It must be used before any changes to the system (return)
   \ stack. So eg it won't work inside a do loop, or in a called word (unless you adjust the param #)

   0 cb-param  1 cb-param  2 cb-param  3 cb-param  ( hwnd uMsg wParam lParam ) \ get the params
 	2 pick case                             \ get uMsg
    	WM_LBUTTONDOWN of 0 PostQuitMessage drop 0 endof	\ screen has been tapped, exit
		WM_PAINT of                            \ process WM_PAINT message
        	3 pick ps BeginPaint  hdc !          	\ get a Device Context for drawing
       	hdc @ 60 70 0 0 u"  Hello World " 0 ExtTextOut drop   \ write our message
       	hdc @ 40 100 0 0 u"  Tap screen to exit " 0 ExtTextOut drop   \ write our message
        	3 pick ps EndPaint drop                 \ finished drawing
    	0 endof
      \ the default case
      drop  \ drop uMsg
      DefWindowProc  \ call the default message handler
   endcase
; 60 cb: winproc  \ make callback   


\ window message processing loop
: msgloop   
	repeat
\   	msg 0 0 0 0 PeekMessage 0if 1 ;; then  \ return 1 (no messages)
      msg 0 0 0 GetMessage 0; drop    \ exit if 0 (quit)
      msg TranslateMessage drop
      msg DispatchMessage drop	\ send message to the Window Procedure.
   again
;

\ This is the main application word
: go    
   ffisetup \ setup the Foreign Function Interface to enable winapi functions (see armwinhdr.f) 

   \ fill in wc (a WNDCLASS struct)
   8 wc ->style !   \ style - DBL_CLKS
   ['] winproc                wc ->wndproc !    
   0                          wc ->cbClassExtra !              
   0                          wc ->cbWndExtra !             
   0  GetModuleHandle         wc ->hInstance !  
   0                          wc ->hIcon !             
   0                          wc ->hCursor !             
   $00ff00 CreateSolidBrush   wc ->hbrBackground !         
   0                          wc ->lpszMenuName !             
   zu" mywinclass"            wc ->lpszClassName ! 

   \ register it
   wc RegisterClass drop       

   \ now create the window 
   0                       \ dwExStyle
   zu" mywinclass"      \ ClassName
   zu" REVA WINDOW"        \ Title
   WS_VISIBLE  WS_CAPTION or WS_BORDER or
   25  60                    \ top, left
   200  200                 \ width, height
   0                       \ parent
   0                       \ HMenu
   0 GetModuleHandle       \ hinstance
   0                       \ lpParam
   CreateWindowEx mywinhandle !

   \ process windows messages
   msgloop
; 
\ End of arm application code

\ make the arm exe image or run the application on the desktop depending on the value of arm
[DEFINED] arm [IF] ' go   here  makearmapp [ELSE] go [THEN]   

bye
