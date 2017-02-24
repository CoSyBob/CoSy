| example of how to create a Window's window, and do something in it.
| based on the FASM example\template.asm
| vim: ts=4 sw=4 :

needs callbacks
needs alg/structs

| Then, we need the actual functions we're going to use:
| NOTE WELL!  You absolutely MUST put the correct number of parameters in the
| declaration.  If you don't, the program WILL crash.  Also, you MUST get the 
| name in quotes and the dll correct, or you will get a NULL pointer to
| dereference, which will also crash.  You have been warned!
k32 drop
1 func:  GetModuleHandleA as GetModuleHandle
g32 drop
5 func:  TextOutA as TextOut
u32 drop
1 func:  RegisterClassA as RegisterClass
12 func:  CreateWindowExA as CreateWindow
2 func:  LoadIconA as LoadIcon
2 func:  LoadCursorA as LoadCursor
1 func:  PostQuitMessage
4 func:  DefWindowProcA as DefWindowProc
4 func:  GetMessageA as GetMessage
1 func:  TranslateMessage
1 func:  DispatchMessageA as DispatchMessage
2 func:  BeginPaint
2 func:  EndPaint

| Stuff from Windows header files:
32512 dup	constant IDI_APPLICATION 
			constant IDC_ARROW
15			constant COLOR_BTNFACE
$010000000	constant WS_VISIBLE
$000080000	constant WS_SYSMENU
$0002		constant WM_DESTROY
$000040000	constant WS_THICKFRAME
$000F		constant WM_PAINT

| Constant strings:
: ourclass z" reva_winapp" ;
: ourtitle z" Reva WinApp" ;

| Declare some structures we will need:
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

| Declare variables based on those structures:
PAINTSTRUCT ps
MSG msg
WNDCLASS wc

| A couple helper variables:
variable hinst
variable hwnd


| This is the Window function
| ( 0:hwnd 1:uMsg 2:wParam 3:lParam )
:: | we only need the XT for the callback, we don't need a name
	| check for destroy msg:
	1 cb-param dup							| msg
	WM_PAINT =if							| process WM_PAINT message
		0 cb-param ps 2dup					| remove msg; set: hwnd ps
		BeginPaint							| leaves HDC on stack
		10 10 " Reva rocks!" TextOut drop	| write our message
		EndPaint 0							| tell Windows we are done
	else 
		WM_DESTROY =if 
			0 PostQuitMessage				| quit message
		else	
			4 0 do i cb-param loop
			DefWindowProc					| pass to default handler
		then
	then					
	; 4 20 stdcb: winproc	| four parameters, give it a 20 deep stack

| Application message loop:
: msgloop 
	repeat
		msg 0 0L GetMessage 0; drop	| if GetMessage got 0, we're done
		msg TranslateMessage drop
		msg DispatchMessage drop
	again										| repeat forever (until 0 received)
	;


| set up the window class for our app:
	0 GetModuleHandle dup hinst ! wc ->hInstance !
	0 IDI_APPLICATION LoadIcon wc ->hIcon ! 
	0 IDC_ARROW LoadCursor wc ->hCursor ! 
	' winproc wc ->wndproc !
	COLOR_BTNFACE 1 + wc ->hbrBackground !
	ourclass wc ->lpszClassName !
	wc RegisterClass drop

| create a window with that class:
 	0 ourclass ourtitle
 	WS_VISIBLE WS_SYSMENU or WS_THICKFRAME or
 	128 128 192 192
 	0 0 hinst @ 0
 	CreateWindow hwnd ! 

." created a window with handle " hwnd @ . cr

| pump the message loop:
 	msgloop

| when we fall out of the message loop it's because we've been shut down:
	." So long!" cr
	bye
