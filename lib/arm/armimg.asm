
; Example of building a WinCE executable using direct coding
	include 'macro\procAPS.inc'
	format	PE GUI
	entry	Start

section '.text' data code readable writeable executable

Start:
	push	lr			; save the return address that called us (we need it to exit)

	; set r7 to point to the reva data stack
	add    r7,pc,dstack-$-8
	add    r7,r7,1600	 ; set r7 to top of stack buffer, since stack grows down
    ;    ldr    r12,[pc,MessageBoxW-$-8]
	add	r12,pc,MessageBoxW-$-8	       ; r12 points to ordinals

	; call the forth application code
    ;    mov    r0,0
    ;    mcr    p15,0,r0,c7,c7,0         ; invalidate  cache

	bl     forthapp
	; exit to windows
	pop    lr			; restore return addr so we exit after message box
	bx     lr		      ; return (exit)

; Start: - is a code label. Precede with "." for local labels
; Caption - is a data label. It does not have a colon and must be followed by a data directive (du)


	align	4
data import
	dw	RVA core_imports,0,0,RVA core_name,RVA core_imports  ; dw - define 32 bit data
	rw	5   ; rw - reserve 32bit data (five 32bit words I guess)
; RVA stands for Relative Virtual Address and returns the Image Relative Offset of the expression
	core_imports:
	MessageBoxW	dw	0x8000035A
	MessageBeep	dw	0x80000359
	LoadLibraryW	dw	0x80000210
	GetProcAddressW dw	0x80000212
	LocalAlloc	dw	0x80000021
	FreeLibrary	dw	0x80000211
	LocalReAlloc	dw	0x80000022
	LocalFree	dw	0x80000024
	WriteFile	dw	0x800000AB
	ReadFile	dw	0x800000AA
	CreateFileW	dw	0x800000A8
	GetFileSize	dw	0x800000AC
	GetLastError	dw	0x80000204
	Sleep		dw	0x800001F0
	GetTickCount	dw	0x80000217
	CloseHandle	dw	0x80000229
	SetFilePointer	dw	0x800000AD
			dw	0

	core_name	db	'COREDLL.DLL',0   ; dw - define 8 bit data

	align	4
end data

; allot some space for the reva data stack. This can later be changed to some allocated space
	align 4
dstack	rw	400		; reserved for stack
	dw	0xabcdef12	; the third top stack item


marker	dw	0x12345678	  ; a marker for reva to find

	; this is the code that is overwritten by reva with the main forth application.
forthapp:
	str	r12,[pc,marker-$-8]  ; save ordinals ptr
