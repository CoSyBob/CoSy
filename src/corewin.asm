; Linux core:
include 'macros'
OS = 0
EOF=26

format PE console
stack 16000
entry _start

struc input_record {
	.type	rd 1
	.keydown rd 1 
	.repeatcount rw 1
	.vkeycode rw 1
	.vscancode rw 1
	.ascii rw 1
;	.unicode rw 1
	.controlkeystate rd 1
}
INVALID_HANDLE_VALUE = -1
STD_INPUT_HANDLE     = -10
STD_OUTPUT_HANDLE    = -11
STD_ERROR_HANDLE     = -12
GENERIC_READ		  = 80000000h
GENERIC_WRITE		  = 40000000h
GENERIC_EXECUTE 	  = 20000000h
GENERIC_ALL		  = 10000000h
CREATE_NEW	  = 1
CREATE_ALWAYS	  = 2
FILE_SHARE_READ 	  = 00000001h
FILE_SHARE_WRITE	  = 00000002h
FILE_SHARE_DELETE	  = 00000004h
FILE_ATTRIBUTE_READONLY   = 001h
FILE_ATTRIBUTE_HIDDEN	  = 002h
FILE_ATTRIBUTE_SYSTEM	  = 004h
FILE_ATTRIBUTE_DIRECTORY  = 010h
FILE_ATTRIBUTE_ARCHIVE	  = 020h
FILE_ATTRIBUTE_NORMAL	  = 080h
FILE_ATTRIBUTE_TEMPORARY  = 100h
FILE_ATTRIBUTE_COMPRESSED = 800h

OPEN_EXISTING	  = 3
OPEN_ALWAYS	  = 4
TRUNCATE_EXISTING = 5

; include "inc/win32a.inc"
macro invoke proc,[arg] 		; indirectly call STDCALL procedure
 { common
    if ~ arg eq
   reverse
     pushd arg
   common
    end if
    call [proc] }
; These macros must be defined prior to the general code:
macro NONBSS {
section '.data' data readable writeable 
}
macro BSS { 
bss_start:
;ir input_record
;processheap rd 1
emit_buffer rd 1
written_buffer rd 1
; fhandle rd 1
numbytes rd 1
;consolemode rd 1
}

KEY_EVENT =1
MOUSE_EVENT =2
WINDOW_BUFFER_SIZE_EVENT =4
MENU_EVENT =8
FOCUS_EVENT =16
CTRL_C_EVENT = 0
CTRL_BREAK_EVENT = 1
CTRL_CLOSE_EVENT = 2
CTRL_LOGOFF_EVENT = 5
CTRL_SHUTDOWN_EVENT = 6
ENABLE_LINE_INPUT = 2
ENABLE_ECHO_INPUT = 4
ENABLE_PROCESSED_INPUT = 1
ENABLE_WINDOW_INPUT = 8
ENABLE_MOUSE_INPUT = 16
ENABLE_PROCESSED_OUTPUT = 1
ENABLE_WRAP_AT_EOL_OUTPUT = 2

section ".code" code readable writeable executable
;---------------------------------------------------------------------
; windows-specific linkage stuff:
align 4
os_start:
	invoke GetModuleHandle, 0
	mov [hinstance], eax
	push eax
	invoke GetModuleFileName, eax, app_file_name, 255
	pop eax

	invoke GetStdHandle, STD_INPUT_HANDLE
	mov [StdIn], eax

	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov [StdOut], eax

.redirected:

	invoke GetCommandLine
	mov [argv], eax
	push esi
	; figure out how many args there are, while modifying the argv if necessary:
	mov esi, eax
	mov edi, esi
	xor eax, eax
	mov [argc], eax		; initially, zero args

	; normal argument
.argloop:
	lodsb		; ESI, source string
	cmp al, '"'
	je .quoteloop
	cmp al, ' '	; space
	je .argspace
	cmp al, 9	; tab
	je .argspace
	or al, al
	jz .argend
	stosb
	jmp .argloop

.quoteloop:
	lodsb		; ESI, source string
	or al, al
	jz .argend
	cmp al, '"'	; space
	je .argspace
	stosb
	jmp .quoteloop

.argspace:	; esi points to a space character
	mov [edi], ah	; NUL terminate
	inc edi
	; scan to end of spaces
.argspace2:
	lodsb
	cmp al, ' '
	je .argspace2
	cmp al, 9
	je .argspace2
	or al, al
	jz .argend
	; now ESI points to next argument, and EDI points to next place to
	; store:
	dec esi
	inc [argc]
	jmp .argloop

.argend:
	inc [argc]
	mov [edi], ah

	; set up exception handler
	pusha
	invoke SetErrorMode, -1
	invoke SetUnhandledExceptionFilter, win_except
	invoke SetConsoleCtrlHandler, ctrl_c, 1
	popa

	pop esi
	ret

;except_code dd 0
;except_addr dd 0
;except_ip   dd 0
align 4
ctrl_c:
	mov ebx, [esp+8]
	push ebp
	mov ebp, esp
	push esi
	sub esp, 8
	mov esi, esp
	sub esp, 80

	cmp ebx, 2	; CTRL_CLOSE_EVENT
	je .close
	call ctrlc_handler
	; mov eax, 1 ; handled the request

	pop esi
	mov esp, ebp
	pop ebp
	ret 4

.close:	jmp os_bye

align 4
win_except:
	push ebp
	mov ebp, esp
	push esi
	sub esp, 8
	mov esi, esp
	sub esp, 80
	; do something with the data passed in:
	mov eax, [ebp+8]	; EXCEPTION_POINTERS
	mov edi, [eax]		; EXCEPTION_RECORD
	mov ebx, [eax+4]	; CONTEXT_RECORD

;	upsh dword [edi+12]	; ExceptionAddress

;	mov ebx, [ebx]		; ContextRecord
	add ebx, 156		; offset to EDI
	upsh dword [ebx]	; EDI
	upsh dword [ebx+4]	; ESI
	upsh dword [ebx+8]	; EBX
	upsh dword [ebx+12]	; EDX
	upsh dword [ebx+16]	; ECX
	upsh dword [ebx+20]	; EAX
	upsh dword [ebx+24]	; EBP
	upsh dword [ebx+40]	; ESP
	upsh dword [ebx+28]	; EIP
	upsh dword [edi]	; ExceptionCode

	push ebx
	call exception	
	pop ebx
	test eax, eax
	jz .fail
	mov dword [ebx+28], eax
	mov eax, -1
.fail:
	pop esi
	mov esp, ebp
	pop ebp
	ret 4

; 	; set up 'per thread' handler
; 	pop eax		; return address
; 	xor ebx, ebx
; 	push ebp
; 	push dword 0
; 	push dword 0
; 	push dword [fs:ebx]
; 	push criterr
; 	push dword [fs:ebx]
; 	mov dword [fs:ebx], esp
; 	jmp eax		; go back to caller

; Critical error handler:
; ALIGN 4
; criterr:
; 	mov  eax, [esp+4]	; esp+4 --> exception record
; 				; esp+8 --> CONTEXT record
; 				; esp+12 -->  ERR structure
; 				; EXCEPT+0 -> exception code
; 				;  + 4 -> flags
; 				;  + 8 -> nested exception
; 				;  + 12  -> exception address
; 				;  + 16 -> numberparams
; 				;  + 20 -> additional data
; 	mov ebx, [eax]
; 	mov [except_code], ebx	; 
; 	mov ebx, [eax+12]
; 	mov [except_addr], ebx
; 	call reset
; 	call exception
; 	mov eax, [esp+12]
; 	mov dword [eax+0xb8], hello
; 	mov eax, 0	; 1 = next handler, 0= continue
; 	ret


;---------------------------------------------------------------------

;---------------------------------------------------------------------
; IMPLEMENTATION OF OS-DEFERRED WORDS
;---------------------------------------------------------------------
os_bye:
	upop ebx
	invoke ExitProcess,ebx
align 4
os_type:
	mov ebx, [esi]
	pusha
	invoke WriteFile, [StdOut], ebx, eax, written_buffer, 0
	popa
	drop2
	ret

align 4
os_emit:
	pusha
	mov [emit_buffer], eax  ; keep it safe
	invoke WriteFile, [StdOut], emit_buffer, 1, written_buffer, 0
	popa
	drop
	ret

align 4
os_key:
	dup
	mov eax, -1
	mov [emit_buffer], eax
	push esi
	invoke ReadFile, [StdIn], emit_buffer, 1, written_buffer, 0
	pop esi
	mov eax, [emit_buffer]
	ret

align 4
os_idle:
	invoke Sleep, 0
	ret

; ( s n <name> -- )
PROC _loadlib
	call _fzt
	push esi
	invoke LoadLibrary, eax
	pop esi
	ret
ENDP _loadlib
PROC _unloadlib
	test eax, eax
	jz .done
	push esi
	invoke FreeLibrary, eax
	pop esi
.done:
	drop
	ret
ENDP _unloadlib

; ( s n lib -- handle )
PROC _osfunc
	upop ebx
	lodsd
	push esi
	invoke GetProcAddress, ebx, eax
	pop esi
	ret
ENDP _osfunc
	
;---------------------------------------------------------------------
; ANS FILE ACCESS WORDS
;---------------------------------------------------------------------
; ( -- fam )
os_ro = GENERIC_READ
os_rw = GENERIC_READ OR GENERIC_WRITE
os_wo = GENERIC_WRITE

; ( c-addr u fam -- fileid ) \   s" file.txt" r/w create-file
PROC io_create
	mov ecx, CREATE_ALWAYS
	mov ebx, os_rw
	jmp openrw.2
ENDP io_create

PROC openr
	mov ebx, os_ro
	jmp openrw.1
ENDP openr

; ( c-addr u -- fileid ) \   s" file.txt" r/o open-file
PROC openrw
	mov ebx, os_rw
.1:
	mov ecx, OPEN_EXISTING

.2:
	mov dword [__ior], 0
	push ebx
	push ecx
	call _fzt
	pop ecx
	pop ebx
	push esi
	invoke CreateFile, eax, ebx, FILE_SHARE_READ, 0, ecx, FILE_ATTRIBUTE_NORMAL, 0
	pop esi
	cmp eax, INVALID_HANDLE_VALUE
	jne .open.0
	push eax
	invoke GetLastError
	mov dword [__ior], eax
	pop eax
.open.0:
	mov ebx, dword [__ior]
	or ebx, ebx
	ret
ENDP openrw

; ( fileid -- ior )
PROC io_close
	push esi
	invoke CloseHandle, eax
	pop esi
	jmp win_return2
ENDP io_close

; ( c-addr u1 fileid -- u2 ) 
PROC io_read
	upop ecx ; [fhandle]; handle
	upop [numbytes]; how many
	push esi
	invoke ReadFile, ecx , eax, [numbytes], written_buffer, 0
	pop esi
	upsh [written_buffer]
	swap
	jmp win_return2
ENDP io_read

; ( c-addr u fileid -- ior )  pad 10 file_desc @ write-file
PROC io_write
	upop ecx ; [fhandle]; handle
	upop [numbytes]; how many
;	mov [tempX], eax ; buffer
	push esi
	invoke WriteFile, ecx, eax, [numbytes], written_buffer, 0
	pop esi
win_return2:
	or eax, eax
	jz .err
	xor eax, eax
.err2:	test eax, eax
	upop dword [__ior]
	ret
.err:	invoke GetLastError
	jmp .err2
ENDP io_write

;FORTH 'GetLastError', _gle
;	dup
;	invoke GetLastError
;NEXT _gle
; ( fileid -- ud )
PROC io_size
	push esi
	invoke GetFileSize, eax ,0 ; [fhandle], 0
	pop esi
	ret
ENDP io_size

; ( c-addr u -- x ior )
; PROC io_status
; 	call _zt
; 	upop ebx
; 	pusha
; 	invoke GetFileAttributes, ebx
; 	mov [tempX], eax
; 	popa
; 	upsh [tempX]
; 	xor ebx, ebx
; 	cmp [tempX], -1
; 	je .io.1
; 	inc ebx
; .io.1:
; 	upsh ebx
; 	ret
; ENDP io_status

_makeexe:	
	drop
	ret
;---------------------------------------------------------------------
; ANS MEMORY ALLOCATION WORDS
;---------------------------------------------------------------------

; ( u -- a-addr )

PROC mem_alloc
;	dup
	invoke LocalAlloc, 0, eax
alloc_return:
	mov ebx, eax
alloc_return2:
	cmp ebx, 1
	sbb ebx, ebx
	mov dword [__ior], ebx
	ret
ENDP mem_alloc

; ( a-addr -- )
PROC mem_free
	invoke LocalFree, eax
	mov dword [__ior], eax
	upop ebx
	ret
ENDP mem_free

; ( a-addr u -- a-addr2 )
PROC mem_realloc
	upop ebx	; EAX -> addr, EBX -> newsize
	invoke LocalReAlloc, eax, ebx, 0
	jmp alloc_return
ENDP mem_realloc

PROC os_syscall
	ret
ENDP os_syscall
; macro simplification from FreeForth:
macro library [name,string] {
  forward
    local _label
    dd RVA name#.lookup,0,0,RVA _label,RVA name#.address
  common
    dd 0,0,0,0,0
  forward
    _label db string,0
    rb RVA $ and 1
}
macro import name,[label,string] {
  common
    name#.lookup:
  forward
    local _label
    dd RVA _label
  common
    dd 0
    name#.address:
  forward
    label dd RVA _label
  common
    dd 0
  forward
    _label dw 0
    db string,0
    rb RVA $ and 1
}
data import

  library kernel,'KERNEL32.DLL'

  import kernel,\
	LocalAlloc, 'LocalAlloc',\
	LocalReAlloc, 'LocalReAlloc',\
	LocalFree, 'LocalFree',\
	GetModuleHandle,'GetModuleHandleA',\
	GetModuleFileName,'GetModuleFileNameA',\
	GetCommandLine, 'GetCommandLineA',\
	ExitProcess,'ExitProcess',\
	GetStdHandle, 'GetStdHandle',\
	WriteFile, 'WriteFile',\
	ReadFile, 'ReadFile',\
	CreateFile, 'CreateFileA',\
	 GetLastError,'GetLastError',\
	 GetFileSize, 'GetFileSize',\
	CloseHandle,'CloseHandle',\
	LoadLibrary,'LoadLibraryA',\
	FreeLibrary,'FreeLibrary',\
	GetProcAddress,'GetProcAddress'  , \
	SetErrorMode,'SetErrorMode'  , \
	SetConsoleCtrlHandler, 'SetConsoleCtrlHandler', \
	Sleep, 'Sleep', \
	SetUnhandledExceptionFilter, 'SetUnhandledExceptionFilter'
end data
section 'rsrc' data readable resource from 'reva.res'

; General code goes here: ---------------------------------------------
include "revacore.asm"
