; Linux core:
OS = 1
EOF=4
include 'macros'

format elf
section '.flat' writeable executable  
public _start
extrn dlopen
extrn dlclose
extrn dlsym
extrn malloc
extrn free
extrn realloc

struc termios {
	.iflag rd 1
	.oflag rd 1
	.cflag rd 1
	.lflag rd 1
	.line rb 1
		rd 1 ; pad
	.cc rb 32
	.ispeed rd 1 
	.ospeed rd 1
		rd 1
}
struc stat_t {
	.dev	rd 2 	; + 0
		rd 1 	; + 8; pad
	.inode	rd 1	; +12
	.mode	rd 1	; +16
	.nlink	rd 1	; +20
	.uid	rd 1	; +24
	.gid	rd 1	; +28
	.rdev	rd 2	; +32
		rd 1	; +40 pad
	.size	rd 1	; +44
	.hsize	rd 1	; +48
	.blksize rd 1	; +52
	.blocks	rd 1	; +56
	.atime	rd 1	; +60
	.mtime	rd 1	; +64
	.ctime	rd 1	; +68
		rd 6	; -- +100
}

linux_read = 3
linux_write = 4
linux_open = 5
linux_close = 6
linux_creat = 8
linux_unlink=10
linux_seek64=140
linux_fstat64=197
linux_ftruncate=194 ; ftruncate64
linux_rename=38
linux_stat=106
linux_fsync=118
linux_signal=48
linux_sigaction=67
linux_sigsuspend=72
linux_sigpending=73
linux_sigreturn=119
linux_getpid=20
linux_readlink=85
linux_select=82
linux_mprotect=125
SEEK_SET=0
SEEK_CUR=1
SEEK_END=2
SIG_ERR=-1
SIG_DFL=0
SIG_IGN=1

SIGHUP=1
SIGINT=2
SIGQUIT=3
SIGILL=4
SIGTRAP=5
SIGABRT=6
SIGBUS=7
SIGFPE=8
SIGKILL=9
SIGUSR1=10
SIGSEGV=11
SIGUSR2=12
SIGPIPE=13
SIGALRM=14
SIGTERM=15
O_RDONLY	    = 0
O_WRONLY	    = 1
O_RDWR		    = 2

; These macros must be defined prior to the general code:
macro BSS { section ".bss" writeable executable
stat_buf stat_t
in_termios   rd 17 ; termios
out_termios  rd 17 ; termios
ourpid rd 1
fd_set  rd 1	; for select call in 'iskey'
tv	rd 2	; also
bss_start:
}
SIGNAL_COUNT = 4
macro NONBSS {
procname db '/proc' ; actually includes the / from 'exe', so don't separate them!
exe db '/exe'
align 4
}
struc sigaction sact, m, f {
	.sa_sigaction dd sact ; void (*sa_sigaction)(int,siginfo*, void *)
	.sa_mask dd m ; sigset_t mask;
	.sa_flags dd f ; int flags
	.sa_restorer dd 0 ; void (*sa_restorer)(void) 
}
; sigcontext structure used in ucontext below
; it contains eip we're going to overwrite when catching signal
struc sigcontext {
        .gs            rw 1
        .__gsh         rw 1
        .fs            rw 1
        .__fsh         rw 1
        .es            rw 1
        .__esh         rw 1
        .ds            rw 1
        .__dsh         rw 1
        .edi           rd 1
        .esi           rd 1
        .ebp           rd 1
        .esp           rd 1
        .ebx           rd 1
        .edx           rd 1
        .ecx           rd 1
        .eax           rd 1
        .trapno        rd 1
        .err           rd 1
        .eip           rd 1
        .cs            rw 1
        .__csh         rw 1
        .eflags        rd 1
        .esp_at_signal rd 1
        .ss            rw 1
        .__ssh         rw 1
        .fpstate       rd 1
        .oldmask       rd 1
        .cr2           rd 1
}

SA_SIGINFO        equ 0x00000004 ; use sa_sigaction instead of sa_handler
new_act sigaction reva_sig_handler, 0, SA_SIGINFO
; structure type for 3rd parameter of signal handler
struc ucontext {
        .uc_flags    rd 1
        .uc_link     rd 1
        .uc_stack    rd 1 ; signaltstack
        .uc_mcontext sigcontext
        .uc_sigmask  rd 1 ; sigset_t
}
virtual at 0
        ucontext ucontext
end virtual
; OS-specific code is here: ---------------------------------------------
os_start:
	; mprotect
;	mov ebx, os_start
;	mov ecx, blz_workmem 
;	sub ecx, ebx
;	mov edx, 7 ; PROT_EXEC|PROT_READ|PROT_WRITE
;	mov eax, linux_mprotect
;	int 80h
;	mov ebx, esp
;	mov ecx, 100000 
;	mov edx, 7 ; PROT_EXEC|PROT_READ|PROT_WRITE
;	mov eax, linux_mprotect
;	int 80h

	mov dword [StdOut], 1
	mov dword [StdIn], 0
	; save argc, argv
	mov eax, [esp+4]
	mov [argc], eax
	mov eax, [esp+8]
	mov [argv], eax
	mov eax, [argc]
;	mov eax, [esp+4*eax+12]
;	mov [environ], eax
	; Now, let's get the pid
	mov eax, linux_getpid
	int 80h
	mov [ourpid], eax

	; get our file path.
	; first construct the file name.
	upsh procname
	upsh 6
	upsh __pad
	call _place
	; convert pid to decimal value
	upsh [ourpid]
	upsh 0
	call _printr	; stack contains the string nnnn corresponding to our pid
	upsh __pad
	call _pplace	; append
	upsh exe
	upsh 4 
	upsh __pad
	call _pplace	; append
	; 'pad' has the proc name corresponding to our EXE.  Let's figure out what it is:
	upsh __pad
	mov ebx, __pad
	inc ebx
	mov edx, 255
	mov ecx, app_file_name
	mov eax, linux_readlink
	int 80h
	cmp eax, -1
	jne .readlinkok
	; failed reading the link, probably we don't have permission.  Assume
	; 'argv[0]' has the correct value (woe to us if it doesn't!)
	upsh [argv]
	call _ztc
	inc eax	; include NUL
	upsh app_file_name
	swap
	call _move
.readlinkok:

	; set signal handlers

       ; The args go in ebx, ecx, edx, esi, edi, ebp, in that order.
       ; (this is from the Linux Assembly HOWTO)

       ; sigaction(signum, sigaction *act, sigact *oldact)
       mov ecx, 12
another:
	push ecx
        mov ebx, ecx
	mov ecx, new_act
	xor edx, edx
	mov eax, linux_sigaction
	int 80h
	pop ecx
	loop another

	mov esi, [tempX]
	; save argc, argv
	ret

align 4
reva_sig_handler:
	mov ebx, [esp+12]	; ucontext
	mov ecx, [esp+4]	; exception

	push ebp
	mov ebp, esp
	push esi
	sub esp, 8
	mov esi, esp
	sub esp, 80

	cmp ecx, 2
	je .break

	push ebx
	upsh [ebx+9*4] ; edi
	upsh [ebx+10*4] ; esi
	upsh [ebx+13*4] ; ebx
	upsh [ebx+14*4] ; edx
	upsh [ebx+15*4] ; ecx
	upsh [ebx+16*4] ; eax
	upsh [ebx+11*4] ; ebp
	upsh [ebx+12*4] ; esp
	upsh [ebx+ (19*4)] ; eip
	upsh ecx 	; exception
	call exception	
	pop ebx
	test eax, eax
	jz .fail
	mov [ebx+19*4], eax
.fail:	
	pop esi
	mov esp, ebp
	pop ebp
	ret

.break:	call ctrlc_handler
	jmp .fail

os_type:
        upop edx                ;
        mov ecx, eax
        or edx,edx              ; Is the count zero?
        jz .done                ; If so, we can exit
        mov ebx, 1              ; stdout
        mov eax, 4              ; sys_write
        int 80h                 ; Linux syscall
.done:
        drop
	ret

os_emit:
	mov ebx, 1	;stdout
	mov edx, ebx	;count
	lea ecx, [esp-4]
	mov [ecx], eax
	mov eax, 4	;sys_write
	int 80h
.done:
	drop
	ret

align 4
os_key:
	dup
	sub ebx,ebx	;0 = stdin
	mov edx, 1	;count
	push ebx
	mov ecx, esp
	mov eax, 3
	int 80h
	dec eax
	jz .ok
	mov dword [esp], -1
.ok:
	pop eax
	ret
os_idle:
;	invoke Sleep, 0
	ret
;os_ekey:
;	dup
;	push esi
;	call non_canonical_input
;	call os_key
;	push eax
;	call term_restore
;	pop eax
;	pop esi
;	ret

TCGETS = 5401h
TCSETS = 5402h
TCSETSW = 5403h
TCSETSF = 5404h

ISIG=1
ICANON=2
XCASE=4
ECHO=10o
ECHOE=20o
ECHOK=40o
ECHONL=100o
NOFLSH=200o
TOSTOP=400o
ECHOCTL=1000o
ECHOPRT=2000o
ECHOKE=4000o
FLUSHNO=10000o
PENDIN=40000o
IEXTEN=100000o

; get terminal state into 'in_termios'
; and also 'out_termios' -- this is the one we play with
;term_save:
;	mov eax, 54
;	xor ebx, ebx
;	mov ecx, TCGETS
;	mov edx, out_termios
;	int 80h

;	mov ecx, TCGETS
;	mov edx, in_termios
;term_do:
;	mov eax, 54
;	xor ebx, ebx
;	int 80h
;	ret
; restore terminal to original state:
;term_restore:
;	mov ecx, TCSETSW
;	mov edx, in_termios
;	jmp term_do

;non_canonical_input:
;	mov edx, out_termios
;	mov dword [edx+12], ECHONL
;	mov ecx, TCSETSW
;	jmp term_do
;;---------------------------------------------------------------------
os_bye:
	mov ebx, eax
	mov eax, 1	;1 = sys_exit
	int 80h

PROC os_syscall
       ; syscalls can take a variable number of arguments, from 0 to 6.
       ; The args go in ebx, ecx, edx, esi, edi, ebp, in that order.
       ; (this is from the Linux Assembly HOWTO)

       ; At entry, the Forth stack holds args, argcount, syscall-number

       ; validate argcount, if > 6 return without changing the stack
           mov ecx, [esi]          ; ecx = argcount
           cmp ecx, 6
           ja .ret

           lea edi, [esi+4 +4*ecx] ; compute data stack adjustment
           push edi                ; save it
           push eax                ; save syscall-number
           mov eax, esi            ; esi modified when argcount>3
           lea ecx, [.6 +4*ecx]    ; i.e. .0-4*argcount
           jmp ecx

.6:        mov ebp, [eax+24]       ; 3-bytes instruction
           nop                     ; 1-byte nop padding
.5:        mov edi, [eax+20]
           nop
.4:        mov esi, [eax+16]
           nop
.3:        mov edx, [eax+12]
           nop
.2:        mov ecx, [eax+8]
           nop
.1:        mov ebx, [eax+4]
           nop
.0:        pop eax                 ; restore syscall-number
           int 80h                 ; eax = syscall result
           pop esi                 ; restore adjusted data stack
.ret:      ret
ENDP os_syscall


; syscall interface ends here
;---------------------------------------------------------------------
; ANS FILE ACCESS WORDS
;---------------------------------------------------------------------
os_ro = O_RDONLY
os_rw =	O_RDWR
os_wo = O_WRONLY

; EAX is system call to make
; parms are EBX, ECX, EDX, ESI, EDI
; retval in EAX, negative on failure

; ior is 0 if succeeded.
macro linux { int $80 }

PROC openrw  ;( a n -- filied )
	mov ecx, O_RDWR
	jmp io_open
ENDP openrw

PROC openr ; ( a n -- fileid )
	mov ecx, O_RDONLY
	; fall through
	
; sys_open(filename, flags, mode) --> handle
; ( c-addr u fam -- fileid ior ) \   s" file.txt" r/o open-file
;	upop ecx	; flags O_RDONLY etc.
io_open:
	call _fzt
	mov ebx, eax	; filename
	xor edx, edx	; mode
	mov eax, linux_open
call_linux:
	linux
call_linux_return: ; convert value in EAX into 'ior'
	mov ebx, eax	
call_linux_return2: ; convert value in EBX into 'ior'
	; ebx<0 --> 1 else 0
	test ebx, ebx
	js .end
	xor ebx, ebx
	jmp .end
.end:	mov dword [__ior], ebx
	test ebx, ebx	; jnz is error
	ret
ENDP openr

; ( fileid -- )
PROC io_close
	mov ebx, eax
	mov eax, linux_close
call_linux2: ; convert value in EAX into 'ior'
	linux
	upop ebx
	jmp call_linux_return2
ENDP io_close

; ( c-addr u -- fileid ior ) \   s" file.txt" r/w create-file
PROC io_create
	call _fzt
	mov ebx, eax	; filename
	mov ecx, 600o
	mov edx, 1000o
	mov eax, linux_creat
	jmp call_linux
ENDP io_create

; ( c-addr u1 fileid -- n )  pad 10 file_desc @ read-file
; sys_read(fd, buf, count)
PROC io_read
	push eax	; fileid
	drop
	mov edx,eax		; count
	drop
	mov ecx	,eax	; count
	pop ebx		; fileid
	mov eax, linux_read
	jmp call_linux
ENDP io_read

; ( c-addr u fileid -- ior )  pad 10 file_desc @ write-file
PROC io_write
	push eax	; fileid
	drop
	mov edx,eax		; count
	drop
	mov ecx	,eax	; count
	pop ebx		; fileid
	mov eax, linux_write
	jmp call_linux2
ENDP io_write

; ( c-addr u -- x ior )
;PROC io_status
;	call _zt
;	push eax 
;	drop
;	pop ebx
;	mov ecx, stat_buf
;	mov eax, linux_stat
;	call call_linux
;	upsh dword [stat_buf.mode]	; third element is ior
;	swap
;	ret
;ENDP io_status

; ( fileid -- ud )
; fstat64(fd, fstat64)
PROC io_size
;	dup
	mov ebx, eax
	mov ecx, stat_buf
	mov eax, linux_fstat64
	linux
	mov eax, dword [stat_buf.size]
;	mov [esi], eax
;	mov eax, dword [stat_buf.hsize]
	ret
ENDP io_size


;---------------------------------------------------------------------
; ANS MEMORY ALLOCATION WORDS
;---------------------------------------------------------------------
; For now I will use the libc routines.
PROC mem_alloc
	push eax	
	call malloc
	add esp, 4
.0:
	mov ebx, eax
	sub ebx, ebx
	sbb ebx, 0
	mov dword [__ior], ebx
	;u
	;upsh 0
	;cmp ebx, 0
	;jnz .1
;	inc eax
;.1:	upop [__ior]
	ret
ENDP mem_alloc

; ( a-addr -- )
PROC mem_free
	push eax
	call free
	add esp, 4
	xor eax, eax
	upop dword [__ior]
	ret
ENDP mem_free

; ( a-addr u -- a-addr2 )
PROC mem_realloc
	push eax
	drop
	push eax
	call realloc
	add esp, 8
	jmp mem_alloc.0
ENDP mem_realloc

; ( s n <name> -- )
PROC _loadlib
	call _fzt
	; load the library:
	push 1 or 0x100	; RTLD_LAZY | RTLD_GLOBAL
	push eax	; library name
	call dlopen
	add esp, 8
	ret
ENDP _loadlib
PROC _unloadlib
	test eax, eax 
	jz .done
	push eax	; library handle
	call dlclose
	add esp, 4
.done:
	drop
	ret
ENDP _unloadlib

; ( s n lib -- handle )
PROC _osfunc
	upop ebx	; EBX is handle
	lodsd		; drop count, EAX is function name
	push esi
	push eax	; symbol
	push ebx	; libhandle
	call dlsym
	add esp, 8
	pop esi
	ret
ENDP _osfunc

_makeexe:
	; chmod = oscall 15
	mov ecx, 448
	mov ebx, eax
	mov eax, 15
	linux
	drop
	ret

;---------------------------------------------------------------------


; General code goes here: ---------------------------------------------
include "revacore.asm"

; Our BSS: ---------------------------------------------
