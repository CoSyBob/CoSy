; main source
; ----------------------------------------------------------------------
; must be a power of 2 (between 8k and 2mb appear reasonable)
BLZ_WORKMEM_SIZE equ 1024*1024
DICTSIZE equ 2000 * 1K
CODESIZE equ 2000 * 1K
STRSIZE equ 4 * 1K
STACKSIZE equ 2 * 1K
; DSTRSIZE equ 4 * 1K
PADSIZE equ 1K
TIBSIZE equ 1K

XT_FIELD equ 4
NAME_FIELD equ 8
CLASS_FIELD equ -4

align 4 
_start:
	mov [_rp0], esp
	; Do one-time startup:
	call os_start
	; load dictionary ...
	mov esi, _s0
	upsh app_file_name
	call _ztc
_load:	; loads the compressed dictionary data and unpacks it correctly:
	call openr	; handle
	dup ; h h 
	call io_size 	; h size
	; h ptr ptr size h
	mov ebx, [esi]	; h -> EBX
	upsh _blz_filebuf
	swap	; h ptr size
	upsh ebx
	call io_read ; h rsize
	swap
	call io_close
	upsh _blz_filebuf
	swap
	; [ESI] -> ptr (need to free it, don't forget!)
	; EAX -> size
	; ( a n )
	mov ebx, [esi]

	; read the header and verify it's ok
	lea edi, [ebx+eax-4]
	cmp dword [edi], 'Reva'
	jne .bye

	; read the total size:
	mov ecx, [edi-4]
	neg ecx
	; get the start of the data we are interested in:
	lea edi, [edi+ecx+4]
	cmp dword [edi], 'Reva'
	jne .bye

	; we have a valid dictionary now: read it in, piece by piece:
	mov ebp, edi	; edi is used by '_move'
	; ( a n )
	; passes our due-diligence.  now read it in:
	; first, copy over our save_header:
	upsh ebp
	upsh save_header
	upsh HEADERSIZE*4
	call _move
	; ( a n )
	; bump ebp to next area
	add ebp, HEADERSIZE*4
	mov [sh_ptr2], ebp	; original data

	; we have to allocate a chunk to hold our decompressed data
	; first, how big will it be?
	mov ecx, [sh_ssz]
	add ecx, [sh_bsz]
	add ecx, [sh_hsz]
	add ecx, [sh_dsz]
	mov [sh_size], ecx	; that's how big
	; the staging area; decompress to there:
	; ( a n p1 )
	mov [sh_ptr1], _blz_buf ; eax
	upsh [sh_ptr1]
	upsh [sh_ptr2]
	upsh [sh_size]
	upsh [sh_ptr1]
	call blz_depack
	drop2
	; ( a n p1 )
	mov ebp, eax 	; [sh_ptr1]
	
	upsh ebp
	upsh static_start
	upsh static_size
	call _move

	add ebp, static_size
	upsh ebp
	upsh bss_start
	upsh bss_size
	call _move

	add ebp, bss_size
	upsh ebp
	upsh _h0
	upsh [sh_hsz]
	call _move

	add ebp, [sh_hsz]
	upsh ebp
	upsh _d0
	upsh [sh_dsz]
	call _move
	; ( a n p1 )

	drop
	jmp .bye ; free the pointer!

	; close the file
.err_drop2:
	drop
.err:	drop
	jmp cold

.bye:	; ( a n )
	drop2

	; Do every-time startup:
PROC cold
	mov esi, _s0
	xor eax, eax
	mov [_rp0], esp

; iterate over 'start handlers' and call each one, in order:
	upsh __onstart
	upsh __start
	call iterate
	call appstart
	; fall into 'byebye'
ENDP cold
byebye:
	mov eax, -1
PROC bye
	push eax
	call cleanup
	dup
	pop eax
	jmp os_bye
ENDP bye
align 4
__onstart:
	mov eax, [eax]
	call eax
	ret

; Code for words' implementation:

PROC doesclass
	dup
	mov eax, [eax-4]
;	sub eax, 4
;	mov eax, [eax]
	cmp dword [is_compiling], 0
	jz mclass

.compile:
	swap
	call literal
	jmp compile
ENDP doesclass
PROC cclass
	mov eax, [eax]
ENDP cclass
PROC vclass
	mov ebx, dword [is_compiling]
	or ebx, ebx
	jnz literal
	ret
ENDP vclass
PROC valclass
	mov ebx, dword [is_compiling]
	or ebx, ebx
	jz cclass
	; compiling.  This item needs to be 'dereferenced'
	call literal
	upsh cclass
	jmp compile
ENDP valclass

PROC fclass_notail
	mov dword [do_tail], 0
	jmp fclass.1
	
ENDP fclass_notail

; 'dclass' is just to keep track of 'defer' words
PROC dclass 
ENDP dclass
	nop
PROC fclass
	mov dword [do_tail], 1
.1:	
	mov ebx, dword [is_compiling]
	or ebx, ebx
	jnz compile
	; fall through
ENDP fclass
PROC mclass
;	mov dword [do_tail], 0
	upop ebx
	jmp ebx	; execute the word
ENDP mclass
PROC mclass_notail
	mov [do_tail], 0
	jmp mclass
ENDP mclass_notail
PROC iclass
	; EAX -> XT
	; EDX -> DICT
	mov dword [do_tail], 0
	cmp dword [is_compiling], 0
	je mclass
	; inline the code:
	; EDX is dictionary entry.  -8 is size
	movzx ecx, byte [eax-1]
	upop edx
	jmp store_here.1
ENDP iclass
PROC store_here	; ( addr n -- ) 
	upop ecx ; n
	upop edx ; source addr
	jecxz .bye
align 4
.1:	mov edi, [h]
	add dword [h], ecx
	jmp _move.a
.bye:	ret
ENDP store_here
PROC compile         
	mov edi, [h]
	sub eax, edi
	sub eax, 5
	mov [edi], byte 0xe8
	inc edi
	stosd
	mov [h], edi
	drop
	ret
ENDP compile
PROC _move	        ;
	upop ecx ; N
	upop edi ; dest      ;
	upop edx
	jecxz .b

	align 4
.a:	mov bl, byte [edx] 
	nop
	mov byte [edi], bl
	inc edx 	       
	inc edi 	        
	loop .a 	  
.b:	ret
ENDP _move

; p0 p1 p2 p3 ... pN xt N
PROC _call
	push ebp
	mov ebp, esp
	sub esp, 4	; esi

	upop ecx		; nparams
	upop edx		; xt to call
	jecxz .1		; no parameters
.0:	push eax
	drop
	loop .0
.1:	
	upsh ecx	; ECX is zero because of the loop...
	mov [ebp-4], esi
	call edx
	mov esi, [ebp-4]

	mov esp, ebp
	pop ebp
noop:
	ret
ENDP _call

PROC header
	call parsews	        ;
	jmp _header
ENDP header

PROC __header
	; align code space:
	call _align
	; align dictionary:
	mov edi,[d]	     
	add edi, 3
	and edi, -4

	; save old information so we can back out of a failed compile:
	push [h]
	pop [lasth]
	mov [lastd], edi
	mov ebx, [last]
	push ebx
	mov ebx, [ebx]
	mov [lastl], ebx

	pop ecx			; [last], was in 'ebx'
	; EBX=last@
	; ECX=last
	; EDI=dictionary entry

	; set the class
	push eax

	mov eax, [default_class]
	stosd

	; set 'last'
	mov [ecx], edi 	        ; last= LFA

	; set the previous pointer:
	mov eax, ebx
	stosd

	; set the XT:
	mov eax, [h]
	stosd

	; set the name:
	pop eax
	stosb

	; write the name into its place:
	upsh edi
	swap
	call _move
	; update the dictionary pointer
	mov [d],edi	        ; d= d+9+length
	; check for 'out of dictionary'
	cmp edi, _dtop
	jb .ok
	call dictgone
.ok:
	ret
ENDP __header

PROC inlinesemi	
	; current word is of the class 'inline'.  make it so...
	mov ecx, [h]		; current 'here'
	mov ebx, [lasth]	; get last 'here'
	sub ecx, ebx		; ECX is size of compiled code
	mov edi, [d]
	mov [edi], ecx
	inc edi
	mov ebp, edi
	mov edx, ebx		; source is old 'here'
	mov [h], ebx		; reset 'here' since code isn't there
	call _move.a
	mov byte [edi], 0c3h	; terminate with a RET
	inc edi
	mov [d], edi		; make sure to save the 'dict' pointer
	; make sure class of word is 'inline
	mov ebx, [last]
	mov ebx, [ebx]		; ebx->dict entry
	mov dword [ebx-4], iclass
	; EDI->''xt''  now set the actual XT field to point here
	mov [ebx+4], ebp
	jmp lbracket
ENDP inlinesemi	
PROC semi 	        ; Compile in an exit to the current word
	call ssemi
	; fall into lbracket
ENDP semi
PROC lbracket	        ; Switch back to the interpreter
	mov dword [is_compiling], 0
	ret	; return to caller of caller
ENDP lbracket
PROC ssemi	        ; Exit a word (; will call this!)
	mov ebx,[h]	        ;
	cmp ebx, _htop
	jb .ok
	call heapgone
.ok:
	cmp dword [do_tail], 0
	jz .notail
	cmp byte [ebx-5],0e8h    ; Was the last thing compiled a CALL?
	jne .notail
.tail:	inc byte [ebx-5]	; --> E9 == jmp 
	ret
.notail:
	; not a call, emplace a 'ret'
	mov byte [ebx], 0c3h	; ret
	inc dword [h]
	ret
ENDP ssemi
PROC parsews ; NOTE: must return 0 on failure!
  	dup
 	call parse_setup
  	inc ecx 	        ;
 	mov ebx, 2009h		; space/tab
  align 4
  .0:	jecxz .1
  	mov al, [edi]
  	dec ecx
  	inc edi
  	cmp al, 0ah
  	jne .0a
  	call do_cr
 	jmp .0
  .0a:
  	cmp al, bh
  	ja .1
  	cmp al, bl
  	jae .0
  .1:
  	dec edi 	        ;
  	inc ecx 	        ;
	mov edx, edi
  	mov [esi],edi	        ; a
	inc edx
  align 4
  .2:	jecxz .3
  	mov al, [edi]
  	dec ecx
  	inc edi
  	cmp al, 0ah
  	jne .2a
  	call do_cr
 	jmp .3
align 4
  .2a:
  	cmp al, bh
  	ja .2
  	cmp al, bl
 	jb .2
  .3:
  	mov eax,edi	        ;
  	mov [tin],edi	        ;
  	sub eax,edx
	ret
ENDP parsews

align 4
parse_setup:	
 	dup
 	mov edi,[tin]	        ; Pointer into TIB
 	mov ecx,[tp]	        ;
 	sub ecx, edi
 	ret

PROC parse	; ( c <text>c -- a n )
 	call parse_setup
	mov ebx, edi
 	mov [esi], edi		; save original string as result
	inc ebx
 	; EDI->next char in stream
 	; ECX = count of chars to process
 align 4
 .0:	mov ah, [edi]		; grab next char
 	inc edi			; move to following character
 	cmp al, ah		; does it match?
 	loopne .0		; no, so do next character
	jecxz .2
.1:
 	; otherwise, we matched.  So in that case return the string and adjust tin
 	; ECX is how many characters remain in the input
 	mov eax, edi
 	mov [tin], edi
 	sub eax, ebx
 	ret
.2:	dec ebx 
	jmp .1
ENDP parse

PROC _align
	mov ebx, [h]
	align 4
.next:
	test ebx, 3
	jz .done
	mov byte [ebx], 90h
	inc ebx
	jmp .next

.done:  mov [h], ebx
	ret
ENDP _align
 
PROC _twodup
	mov ebx, [esi]
	lea esi, [esi-8]
	;sub esi, 8	; space for two more
	mov [esi], ebx
	mov [esi+4], eax
	ret
ENDP _twodup

; ( str len buf -- )
PROC _place
	or eax, eax
	jz .4
	mov ebx, [esi+4]
	or ebx, ebx
	jz .3
	mov ebx, [esi]
	mov [eax], bl
.1: 	inc eax
	xchg eax, [esi]
	call _move
	mov byte [edi], 0
	ret
.3:	mov byte [eax], 0
.4: 	drop2
	drop
	ret
ENDP _place

PROC _printr
	upop ebp
	and ebp, 255		; clamp width
	mov edi, _npad	        ; edi = buffer (in stack space)
	mov bl, ' '
	mov ecx, [base]
	cmp ecx, 10
	jne .a
	or eax,eax	        ; Negative?
	jns .a		        ;
	neg eax 	        ;
	mov bl, '-'

.a:	xor edx,edx	        ;
	div ecx		        ;
	add dl,'0'	        ;
	cmp dl,'9'	        ;
	jbe .b		        ;
	add dl,7	        ;
.b:	dec edi 	        ;
	mov [edi],dl	        ;
	or eax,eax	        ;
	jnz .a		        ;

	cmp bl, '-'
	jne .c
	dec edi
	mov [edi], bl
.c:
	mov eax,edi	        ; Print
	dup
	mov eax, _npad
	sub eax, edi
	; fixup width
	mov ecx, ebp
	sub ebp, eax
	jle .e
	mov ebx, [padchar]
.d:	dec edi
	mov [edi], bl
	dec ebp
	jnz .d
	mov [esi], edi
	mov eax, ecx
.e:	ret
ENDP _printr

PROC  _pplace	; append string
	movzx edx, byte [eax]	; get current count
	mov ebx, [esi]		; second size
	add byte [eax], bl 	; bump size:
	add eax, edx 		; bump target ptr
	jmp _place.1
ENDP _pplace

; : variable 0
PROC variable
	upsh 0
ENDP variable
PROC variable2
	push dword [default_class]
	mov dword [default_class], vclass
	call header
	pop dword [default_class]
	jmp comma
ENDP variable2

PROC literal        ; Compile in a literal
	mov ebx, [h]
	; dup | mov eax, imm32
	mov dword [ebx], $89fc768d
	mov word [ebx+4], $b806
	add dword [h], 6
ENDP literal
PROC comma 	        ; comma (,) saves a value to "here"
	mov ecx, 4
.0:
	mov edi, [h]
	mov [edi], eax		; stosw without add edi,4
	add [h], ecx		; bump HERE by correct amount
	drop
	ret
ENDP comma

PROC comma3	        ; comma2 (2,) saves 2 bytes to "here"
	mov ecx, 3
	jmp comma.0
ENDP comma3
PROC comma2	        ; comma2 (2,) saves 2 bytes to "here"
	mov ecx, 2
	jmp comma.0
ENDP comma2
PROC comma1	        ; comma1 (1,) saves 1 byte to "here"
	mov ecx, 1
	jmp comma.0
ENDP comma1

; ( a n -- a' n' NC | CF )
PROC _slurp
	mov dword [__ior], 0
	call openr	; handle? ior
	jnz .err	; h (invalid)
	mov [slurpy], eax ; eax is handle; save it for later use
	; get file size
	dup
	; h h 
	call io_size
	; h sl
	mov [slurpySize], eax
	call mem_alloc
	test eax, eax
	jz .memerr
	; h ptr
	dup ; h ptr ptr
	upsh dword [slurpySize]
	upsh dword [slurpy]
	; h ptr ptr size h
	call io_read
	jnz .memerr
	; h ptr rsize
	rot
	call io_close 
.ok:	clc
	ret
.memerr: ; h ptr
	drop
	call io_close
.err:	; ior
	drop
	upsh 0
	upsh 0
.err1:
	stc
	ret	
ENDP _slurp

PROC eval	        ; This takes an address & count to eval
	push dword [source]     ; Save "source"
	push dword [tin]        ; Save ">in"
	push dword [tp]         ; Save "tp"
	add eax,[esi]	        ;
	upop dword [source]	        ; New "source"
	upop [tin]	        ; New ">in"
	call interpret
	pop dword [tp]	        ;
	pop dword [tin]         ;
	pop dword [source]      ;
	ret
ENDP eval
; ( <name> -- )
PROC _include
	call parsews
	; fall-through
ENDP _include
; ( a n -- CF )
PROC __include
	call _slurp
	jc .fail
	; ptr size
	push dword [esi]	; save the memory ptr
	push esi
	push eax
	call eval
	pop eax
	pop esi
	drop
	pop eax
	call mem_free
.ok:	mov dword [__ior], 0
	ret
.fail:	drop2
	mov dword [__ior], 1
	ret
ENDP __include

; ( buf count char -- )
PROC _fill
	upop ebx	; char
	upop ecx	; count
	upop edx	; buffer
	jecxz .done
.next:	mov [edx], bl
	inc edx
	loop .next
.done:
	ret
ENDP _fill
align 4
_fzt:	; ( str len -- str ) ; copy to a temp buffer first
	call _twodup
	dup
	mov eax, fzt_buf
	swap
	call _move
	mov dword [esi], fzt_buf
	; fall through
; ( str len -- str )
PROC _zt
	upop edx
	test eax, eax
	jz .no
	add edx, eax
	mov byte [edx], 0
.no:
	ret
ENDP _zt
PROC _ztc
	dup
	cmp eax, 0
	jz .q
align 4
.a:     cmp byte [eax],0
        jz .q
        cmp byte [eax + 1],0
        lea eax, byte [eax + 2]
        jnz .a
        dec eax
.q:     sub eax,[esi]
	ret
ENDP _ztc

; ( xt -- exception# | 0 )

; interpreter goes here:
PROC interpret
.o:	call query	        ; ( Get a LINE )
align 4
.word:	call parsews	        ; NOTE: parsews must return 0 on failure!
	jz .nogo
; ----------------------------------------------------------------------
; Tokenizer: reads one word from input, and converts it to a token
; ( a n -- 0 | xt 1 | n 2 | n n 3 | 4 )
; TOS on return is one of:
;   0 - error, can't parse it
;   1 - XT of a found word
;   2 - one cell value
;   3 - then double-cell value
;   4 (or greater) - ignore
; Calls 'is_word', which permits the user to hook into this process and over-
; ride it if desired.  The 'is_word' is passed the string to parse on the stack.

.token:
	call findinternal ;  _find	; look for an XT
	test eax, eax
	jz .trynum	; failed, look for a number
	; success!
	mov ecx, 1
	jmp .afterok
.trynum:	
	drop
	call single	; try a number
	upop ecx
	test ecx, ecx
	jnz .single
	call double
	upop ecx
	test ecx, ecx
	jnz .double
.tryother:
	call is_word
	upop ecx
	jecxz .fail
	jmp .afterok
.double:
	mov ecx, 3
	jmp .afterok
.single:
	mov ecx, 2
.afterok:
	dec ecx
	jnz .lit
	mov edx, eax
	mov edi, [eax+CLASS_FIELD]
	mov eax, [eax+XT_FIELD]
	call edi
	jmp .word	        ; ( And Loop back )
.lit:	cmp dword [is_compiling], 1
	jne .word
	cmp ecx, 1
	je .lit1
	cmp ecx, 2
	jne .word
	swap
	call literal
.lit1:  call literal
	jmp .word
.nogo:  drop2
	jmp .o
.fail:	mov ecx, [is_compiling]
	jecxz .notcompile
	mov dword [is_compiling], 0
	; blow away last word so we don't try to use it:
	mov ebx, [lasth]
	mov [h], ebx
	mov ebx, [lastd]
	mov [d], ebx
	mov ebx, [lastl]
	mov edx, [last]
	mov [edx], ebx
.notcompile:
	ret	
ENDP interpret

query:
	mov dword ecx,[source]  ;
	jecxz .kbd
	upsh [tin]
	or eax, eax
	jz .eof

	mov [tin],eax	        ;
	sub ecx,eax	        ; Remaining length
	jbe .eof	        ;

	add eax, ecx
	inc ecx

	upop [tp]	        ;
	clc
	ret		        ;
.eof:	pop ebx
.eof2:  drop		        ;
	clc
	ret
align 4
.kbd:	call prompt
	mov dword [tp],tib      ; Reset TP, TIN
	mov dword [tin],tib     ;
.c:	
	call key	        ; Get a keypress
	cmp eax, -1
	je bye
	cmp eax, EOF
	je bye
.ok:

;	upsh eax
;	call hexout
;	cmp dword [__ior], 0
;	jne .eof3
.redir:
	cmp al, 10	        ;
	je .eof2		        ;
	cmp al, 13	        ;
	je .d2		        ;
	cmp al, 9		; convert keyed-in TABs into spaces:
	je .tab
	cmp al, 8		; is it a backspace?
	je .bs
.d:	mov ebx, [tp]
	mov [ebx], al
	inc ebx
	mov [tp], ebx
.d2:
	drop		        ;
	cmp dword [tp], tibtop
	jb .c		        ; And Loop back around
	jmp .eof2
.tab:	mov al, ' '
	jmp .d
.bs:	dec [tp]
	cmp [tp], tib
	jae .c
.badbs: mov [tp], tib
	jmp .c

__find:
	push ebx
	mov ebx, [last]

	upop ecx	        ;
	push esi
	mov esi,eax	        ;
	mov dh,  byte [eax]     ; get first char to do quick compare:
	mov dl, cl		; and the length; do both compares at once!
align 4 
.a:	mov ebx,[ebx]	        ;
	test ebx,ebx	        ;
	jz .end 	        ; end of wordlist
	lea edi, [ebx+NAME_FIELD]	; point edi at the string
	cmp dx, [edi]		
	jne .a
	inc edi

.len:   push esi	        ; same length, so do the compare
	push ecx	        ;
	repe cmpsb	        ;
	pop ecx 	        ;
	pop esi 	        ;
	jne .a		        ;

.ret3:  mov eax,ebx         ; exact match: return XT
.ret:	pop esi
.ret2:  pop ebx 	        ;
	ret
.end:	pop esi
	upsh ecx	        ; no matches
	upsh 0
	jmp .ret2

align 4
word_not_found:			; What to do if we can't find a word
	call type		; Display the name
	upsh '?'
	call emit
	upsh 10
	call emit
	upsh 0
	ret

hexout:
	dup
	and eax, 0f0h
	call todigit
	call emit
	and eax, 0fh
	call todigit
	call emit
	ret
; ----------------------------------------------------------------------
align 4
fromdigit_ebx:
	sub ebx, 30h ; 0
	js .bad
	cmp ebx, 4ah
	ja .bad
	movzx ebx, byte [fromdigits + ebx]
	cmp ebx, [base]
	jae .bad
.ok:	ret
.bad:   mov ebx, -1
	ret

PROC fromdigit
	mov ebx, eax
	call fromdigit_ebx
	mov eax, ebx
	ret
ENDP fromdigit
PROC todigit		; ( n -- c )  ---- convert digit to correct ASCII 
	cmp al, 16
	jae .weird
	mov al, byte [digits+eax]
	ret
.weird: mov ebx, [base]
	xor edx, edx
	div ebx
	add dl,'0'	        ;
	cmp dl,'9'	        ;
	jbe .b		        ;
	add dl,7+32	        ;
.b:	mov al, dl
	ret
ENDP todigit
; ----------------------------------------------------------------------
; ( a n -- n -1 | a n 0 ) 
PROC single
	push [base]
	push eax
	push esi
	push dword 1	; negative?

	; set up for the current base
	mov ebp, [base]

	; set up for processing:
	upop ecx
	jecxz .err

	mov edi, eax
	xor eax, eax

	; leading '-' is valid 
	cmp byte [edi], '-'
	jne .s1

	; negative:
	dec dword [esp]
	dec dword [esp]

	inc edi
	dec ecx
	jz .err

.s1:	; check for special base switch char:
	movzx ebx, byte [edi]
	; #$%&'
	sub ebx, '#'
	js .s2
	cmp ebx, 4
	ja .s2
	je .base255
	; in-range, so get the base
	movzx ebp, byte [bases+ebx]
	mov [base],ebp
	inc edi
	dec ecx
	jz .err

.s2:	; process each character	
	; make sure it's a valid character:
	movzx ebx, byte [edi]
	call fromdigit_ebx
	cmp  ebx, ebp
	jae .err
	cmp ebx, -1
	je .err
	; it's valid: do the multiplication+accumulate
	mul ebp		; eax *= base
	jo .err
	add eax, ebx
	jo .err
	inc edi
	loop .s2

.s4:	; end of input string.  EAX is the number.  
	pop ebp
	mul ebp
	pop esi
	pop ebx		; toss away old count 
	add esi, 4	; fix up the stack
.ok:	upsh -1
	pop [base]
	ret
.err:	pop ebx
	pop esi
	pop eax
	pop [base]
	upsh 0
	ret

.base255:
	drop
	inc edi
	movzx eax, byte [edi]
	jmp .s4
ENDP single

PROC double
	push [base]
	push eax
	push esi
	push dword 1	; negative?

	; set up for the current base
	mov ebp, [base]

	; set up for processing:
	upop ecx
	jecxz single.err

	mov edi, eax
	xor eax, eax
	xor esi, esi

	; require final L:
	cmp byte [edi+ecx-1], 'L'
	jne single.err
	dec ecx

	; leading '-' is valid 
	cmp byte [edi], '-'
	jne .d1

	; negative:
	dec dword [esp]
	dec dword [esp]

	inc edi
	dec ecx
	jz single.err

.d1:	; check for special base switch char:
	movzx ebx, byte [edi]
	; #$%&'
	sub ebx, '#'
	js .d2
	cmp ebx, 3
	ja .d2

	; in-range, so get the base
	movzx ebp, byte [bases+ebx]
	mov [base], ebp
	inc edi
	dec ecx
	jz single.err

.d2:	; process each character	
	; make sure it's a valid character:
	movzx ebx, byte [edi]
	; permit commas and periods
	cmp bl, '.'
	je .ignore
	cmp bl, ','
	je .ignore

	call fromdigit_ebx
	cmp  ebx, ebp
	jae single.err
	cmp ebx, -1
	je single.err
	; it's valid: do the multiplication+accumulate
	; ESI:EAX is double
	mul ebp		; eax *= base
	; edx is carry.  Save it
	push edx
	xchg eax, esi
	mul ebp
	xchg eax, esi
	pop edx
	; add carry:
	add esi, edx
	; add digit:
	add eax, ebx
	adc esi, 0
.ignore:
	inc edi
	loop .d2

.d4:	; end of input string.  EDX:EAX is the number.  
	pop ebp
	cmp ebp, -1
	jne .d5
	not esi
	neg eax
	sbb esi, -1
.d5:
	mov edx, esi
	pop esi
	pop ebx		; toss away old count 
	pop [base]
	add esi, 4	; fix up the stack
	upsh edx
.ok:	upsh -1
	ret
ENDP double

PROC parse_with_escape
	mov ebx, '\' 
.top:
	mov edi,[tin]	        ; Pointer into TIB
	mov ecx,[tp]	        ;
	lea ecx, [edi*-1+1]
	mov bh, al		; bl = \  bh = parsechar
	mov ebp, parse_buf 	; ebp = current output location
	xchg esi, edi		; edi == old ESI, esi=src
	; skip leading delimiter:
	lodsb
align 4
	; skip until trailing character
	; al is already something other than the terminator
.2:	cmp al, bl
	je .escaped
	; not escaped check for end of run
	cmp al, bh
	je .endofstring
	; neither end of string nor escaped:
.onechar:
	mov byte [ebp], al
	inc ebp
	lodsb
	loop .2

	; we ended the loop one way or the other
.endofstring:
	xchg edi, esi	; restore the 'stack' ptr
	mov eax, parse_buf
	dup
	sub eax, ebp
	neg eax
	mov [tin], edi
	ret

.escaped:
	lodsb
	dec ecx
	jmp .onechar
ENDP parse_with_escape

; simple 'load one file' for the revacore:
_hello:
	upsh [argc]
	cmp eax, 1
	je .done
	drop
	upsh [argv]
	call _ztc
	upop ebx
	add eax, ebx
	inc eax
	call _ztc
	call __include
;	ret
.done:	drop
	call interpret
	ret

PROC _save	; ( a n -- )
	call cleanup
	call _twodup	; ( a n a n )
	; open the file
	call io_create
	jnz .err1 ; ( a n h )
	mrot
	call _fzt
	call _makeexe
	; EAX is file handle - save it
	dup	; ( h h )

	mov [sh_sig], 'Reva'
	mov [sh_sig2], 'Reva'
	; ok, so read in our exe and write it out:
	upsh app_file_name
	call _ztc
	call _slurp
	; ( h h a n )
	jc .err2	; 
	; stack has: fh fh ptr size
	; adjust size if there is already a dictionary appended:
	mov ebx, [esi]
	mov ecx, [ebx+eax-4]
	cmp ecx, [sh_sig] ; 'Reva'
	jne .nosig
	mov ecx, [ebx+eax-8]
	sub eax, ecx
.nosig:
	; save our ptr:
	mov ebx, [esi]
	mov [slurpy], ebx
	; write out the exe
	rot
	call io_write
	dup
	; ( fh fh )
	mov [sh_ssz], static_size
	mov [sh_bsz], bss_size
	mov ecx, [h]
	sub ecx, _h0
	mov [sh_hsz], ecx


	; calculate the total size of our data:
;	upsh [sh_dsz]
;	add eax, [sh_hsz]
	upsh [sh_hsz]
	add eax, [sh_bsz]
	add eax, [sh_ssz]
	xor ecx, ecx
	mov ebx, [nosavedict]
	mov ecx, [d]
	sub ecx, _d0
	or ebx, ebx
	jnz .nosave1
	add eax, ecx ; [sh_dsz]
.nosave1:
	mov [sh_dsz], ecx

	dup	; stack has ( size size )
	mov [sh_size], eax	; save our size for later use
	; what is the max we need to have:
	call blz_maxsize
	; allocate a buffer that big:
	call mem_alloc
	upop [sh_ptr2]	; save our dest ptr for compression
	call mem_alloc
	upop [sh_ptr1]	; save the src ptr for compression

	; copy all our data to the sh_ptr1 staging area:
	mov  ebx, [sh_ptr1]
	push ebx

	upsh static_start
	upsh ebx
	upsh dword static_size
	call _move
	pop ebx
	add ebx, dword static_size
	push ebx

	upsh bss_start
	upsh ebx
	upsh dword bss_size
	call _move
	pop ebx
	add ebx, dword bss_size
	push ebx

	upsh _h0
	upsh ebx
	upsh dword [sh_hsz]
	call _move
	pop ebx
	add ebx, [sh_hsz]
	push ebx
	
	mov edx, [nosavedict]
	or edx, edx
	jnz .nosave2
	upsh _d0
	upsh ebx
	upsh dword [sh_dsz]
	call _move
	pop ebx
	add ebx, [sh_dsz]
	push ebx
.nosave2:

	pop ebx

	; all the data are in sh_ptr,sh_size  now compress
	upsh [sh_ptr1]
	upsh [sh_size]
	upsh [sh_ptr2]
	call blz_pack
	mov [sh_size], eax
	drop2

	mov [sh_total], dword 0
	upsh save_header
	upsh dword HEADERSIZE*4
	call saveit

	upsh [sh_ptr2]
	upsh [sh_size]
	call saveit

	; write out the full size of data written so-far:
	upsh sh_total
	upsh 8
	call saveit
	drop

	call io_close
.err:	ret
.err2:	; ( h h 0 0 ) close the errant handle
	rot
	call io_close
.err1:  drop2
	drop
	ret
ENDP _save
saveit: ; fh fh ptr size
	test eax, eax
	jz .d2
	add [sh_total], eax
	rot
	call io_write
	dup
	ret
.d2:	drop2
	ret

PROC colon 	        ; Ok, this is the entry to the compiler
	call header
	;call rbracket
	;ret 
ENDP colon

PROC rbracket	        ; This is the actual compiler loop
	mov dword [is_compiling], 1
	ret
ENDP rbracket

; class modifiers:
PROC _forth
	mov dword [default_class], fclass
	ret
ENDP _forth
PROC _macro
	mov dword [default_class], mclass
	ret
ENDP _macro

; compare a1 and a2; if identical upto min(n1,n2) then (n1==n2)?0:(n1<n2)?-1:1;
; ( a1 n1 a2 n2 -- result )
PROC compare
	upop edx	; n2
	upop edi	; a2
	upop ecx	; n1

; Internal routine:
; EAX:ECX --> string1
; EDI:EDX --> string2
; leaves EAX=result
; trashes EDI, ECX,, EDX
strcmp:
	push esi
	mov  esi, eax	; a1
	mov  eax, edx	; n2
	sub  edx, ecx	; n2-n1
	neg  edx
	cmp  ecx, eax
	jl .ok1
	mov ecx, eax	; compare for shorter of two lengths
.ok1:	jecxz .done
	repe cmpsb 	; if Z then strings compare equal
.done1:
	jz .equal
	mov al, [esi-1]	; do lexicographic compare
	sub al, [edi-1]
	movsx eax, al
	jmp .done
.equal: mov eax, edx
.done: 	pop  esi
	ret
ENDP compare

PROC comparei
	upop edx	; n2
	upop edi	; a2
	upop ecx	; n1
strcmpi:
	push esi
	mov  esi, eax	; a1
	mov  eax, edx	; n2
	sub  edx, ecx	; n2-n1
	neg  edx
	cmp  ecx, eax
	jl .ok1
	mov ecx, eax	; compare for shorter of two lengths
.ok1:	jecxz .done
	
.ok2:	mov al, [esi]
	inc esi
	mov ah, [edi]
	inc edi

	or eax, 02020h
	sub al, ah
	jnz .neq
	loop .ok2
.equal: mov eax, edx
	jmp .done
.neq:	movsx eax, al
.done: 	pop  esi
	ret
ENDP comparei

; Implementation of FNV-1a hash:  http://www.isthe.com/chongo/tech/comp/fnv/
; ( str len -- hash )

PROC  fnvhash
	upop ecx	; ECX is len, EAX is stringptr
	mov ebx, eax
.0:
	mov eax, 2166136261	; offset-basis
	mov ebp, 16777619	; FNV prime (32bits)

.1:
	xor al, [ebx]
	mul ebp
	inc ebx
	loop .1
	ret
ENDP fnvhash

PROC onexit
	upsh __exit
	jmp link
ENDP onexit
; iterate over 'exit handlers' and call each one, in reverse order:
PROC cleanup
	upsh __onstart
	upsh __exit
	call iterate
	ret
ENDP cleanup

PROC catch
	; save data stack
	push esi
	; save value of current handler
	push [handler]
	; save value of ESP to 'handler'
	mov [handler], esp
	; execute the XT we got:
	mov ebx, eax
	lodsd
	call ebx
	; if we are here, no 'throw' happened so clean the stack
	pop [handler]
	pop ebx	; get rid of saved ESI
	upsh 0	; make sure caller knows there was no failure
	ret
ENDP catch
PROC throw
	test eax, eax
	jz .nothrow
	; throw code in eax - return control to caller of 'catch'
	mov ebx, [handler]
	test ebx, ebx
	jz .nothrow	; blech!  NULL makes a poor handler...
	mov esp, ebx	; set ESP back to the context of the catch
	pop [handler]	; restore old handler
	pop esi		; restore previous data stack, but with throwcode on top
	ret		; return to caller
.nothrow:
	drop
	ret
ENDP throw

PROC _argv
	upsh [argv]
	ret
ENDP _argv
PROC _argc
	upsh [argc]
	ret
ENDP _argc

PROC onstartup
	upsh __start
;	jmp link2
ENDP onstartup
PROC link2 ; ( dataptr listptr -- )
	; go to the end of the list
	mov ebx, eax	; prior ptr in EBX
.a:	mov eax, [eax]	; get previous ptr
	or eax, eax
	jz .b
	mov ebx, eax
	jmp .a
.b:	; EAX is zero, EBX is last ptr.
	mov eax, ebx
	; fall through to 'link'
ENDP link2
PROC link
	; ( dataptr listptr -- )
	mov edx, [h]
	mov ebx, [eax]	; dataptr listptr ebx=prior-item
	mov [eax], edx  ; put here-> listptr
	drop
	mov [edx], ebx	; prior-item --> here
	mov [edx+4], eax
	add dword [h], 8 
	drop
	ret
ENDP link

PROC iterate
	; ( xt list -- )
	upop ecx	; list
	upop ebx	; XT
	or ebx, ebx
	jz .done

.1:	mov ecx, [ecx]
	jecxz .done

	push ecx
	push ebx
	lea edx, [ecx+4]
	upsh edx
	call ebx
	pop ebx
	pop ecx
	upop edx
	or edx, edx
	jnz .1
.done:	ret
ENDP iterate
; ------ COMPRESS (LZSS) ROUTINES
include 'brieflz.asm'
; ------ COMPRESS (LZSS) ROUTINES

HEADERSIZE = 5
; -- END STUBS --
; ----------------------------------------------------------------------
; This gets persisted:
; ----------------------------------------------------------------------
align 4
static_start:
	DEFER prompt
	DEFER appstart, _hello 
	DEFER key, os_key
	DEFER findinternal, __find
	DEFER is_word, word_not_found
	DEFER type, os_type
	DEFER emit, os_emit
	DEFER do_cr
	DEFER exception, os_bye
	DEFER ctrlc_handler, os_bye
	DEFER heapgone, os_bye
	DEFER dictgone, os_bye
	DEFER _header, __header


mylink=0
	DICT 'exception', exception, exception.dict,dclass
	DICT 'heapgone', heapgone, heapgone.dict,dclass
	DICT 'dictgone', dictgone, dictgone.dict,dclass
	DICT 'ctrl-c', ctrlc_handler, ctrlc_handler.dict,dclass
	DICT 'do_cr', do_cr, do_cr.dict,dclass
	DICT 's0',s0,s0.dict,cclass
	DICT 'd0',d0,d0.dict,vclass
	DICT 'h0',h0,h0.dict,vclass
	DICT 'ioerr',__ior,__ior.dict,vclass
	DICT 'str0',__str0,__str0.dict,cclass
	DICT 'rp0',rp0,rp0.dict,cclass
	DICT "padchar",padchar,padchar.dict,vclass
	DICT '>in',tin,tin.dict,vclass
	DICT 'tib',_tib,_tib.dict,vclass
	DICT 'tp',tp,tp.dict,vclass
	DICT 'src',source,source.dict,vclass
	DICT 'state',is_compiling,is_compiling.dict,vclass
	DICT 'dict',d,d.dict,vclass
	DICT '(here)',h,h.dict,vclass
	DICT 'pad',_pad,_pad.dict,cclass
	DICT 'last',last,last.dict,cclass
	DICT 'base',base,base.dict,vclass
	DICT '(argv)',_argv,_argv.dict
	DICT 'argc',_argc,_argc.dict
	DICT 'hinst',hinstance,hinstance.dict,valclass
	DICT 'stdout',StdOut,StdOut.dict,valclass
	DICT 'stdin',StdIn,StdIn.dict,valclass
	DICT 'os',_os,_os.dict,cclass

	DICT 'syscall',os_syscall,os_syscall.dict
	DICT 'nosavedict',nosavedict,nosavedict.dict,vclass
	DICT 'cold',cold, cold.dict
	DICT 'prompt',prompt,prompt.dict,dclass
	DICT 'default_class',default_class,default_class.dict, vclass
	DICT '>lz',blz_pack,blz_pack.dict
	DICT 'lz>',blz_depack,blz_depack.dict
	DICT 'lzmax',blz_maxsize,blz_maxsize.dict
	DICT "'variable",vclass,vclass.dict
	DICT "'constant",cclass,cclass.dict
	DICT "'does",doesclass,doesclass.dict
	DICT "'value",valclass,valclass.dict
	DICT "'forth",fclass,fclass.dict
	DICT "'notail",fclass_notail,fclass_notail.dict
	DICT "'macro",mclass,mclass.dict
	DICT "'inline",iclass,iclass.dict
	DICT "'macront",mclass_notail,mclass_notail.dict
	DICT "'defer",dclass,dclass.dict
	DICT 'catch',catch,catch.dict
	DICT 'throw',throw,throw.dict
	DICT 'onexit',onexit,onexit.dict
	DICT 'onstartup',onstartup,onstartup.dict
	DICT '(lib)',_loadlib,_loadlib.dict
	DICT '(-lib)',_unloadlib,_unloadlib.dict
	DICT '(call)',_call,_call.dict
	DICT '(func)',_osfunc,_osfunc.dict
	DICT 'fnvhash',fnvhash,fnvhash.dict
	DICT '(bye)',bye,bye.dict
	DICT 'cmp',compare,compare.dict
	DICT 'cmpi',comparei,comparei.dict
	DICT 'place',_place,_place.dict
	DICT '+place',_pplace,_pplace.dict
	DICT 'move',_move,_move.dict
	DICT 'fill',_fill,_fill.dict
	DICT 'zt',_zt,_zt.dict
	DICT 'zcount',_ztc,_ztc.dict
	DICT 'open/r',openr,openr.dict
	DICT 'open/rw',openrw,openrw.dict
	DICT 'creat',io_create,io_create.dict
	DICT 'close',io_close,io_close.dict
	DICT 'read',io_read,io_read.dict
	DICT 'write',io_write,io_write.dict
	DICT 'fsize',io_size,io_size.dict
	DICT 'allocate',mem_alloc,mem_alloc.dict
	DICT 'free',mem_free,mem_free.dict
	DICT 'resize',mem_realloc,mem_realloc.dict
	DICT 'header',header,header.dict
	DICT '(header)', _header, _header.dict, dclass
	DICT 'literal',literal,literal.dict, mclass
	DICT ';;',ssemi,ssemi.dict, mclass
	DICT ';inline',inlinesemi,inlinesemi.dict, mclass
	DICT 'parsews',parsews,parsews.dict
	DICT 'align',_align,_align.dict
	DICT 'here,',store_here, store_here.dict
	DICT 'compile',compile,compile.dict
	DICT 'interp',interpret,interpret.dict
	DICT 'key',key,key.dict,dclass
	DICT 'appstart',appstart,appstart.dict,dclass
	DICT 'emit',emit,emit.dict,dclass
	DICT '(find)',findinternal,findinternal.dict,dclass
	DICT '>single',single,single.dict
	DICT '>double',double,double.dict
	DICT 'word?',is_word,is_word.dict,dclass
	DICT 'type',type,type.dict,dclass
	DICT 'digit>',fromdigit,fromdigit.dict
	DICT '>digit',todigit,todigit.dict
	DICT ':',colon,colon.dict, mclass
	DICT ';',semi,semi.dict, mclass
	DICT '[',lbracket,lbracket.dict, mclass
	DICT ']',rbracket,rbracket.dict, mclass
	DICT '2dup',_twodup,_twodup.dict
	DICT 'variable',variable,variable.dict
	DICT 'variable,',variable2,variable2.dict
	DICT ',' , comma, comma.dict
	DICT '3,' , comma3, comma3.dict
	DICT '2,' , comma2, comma2.dict
	DICT '1,' , comma1, comma1.dict
	DICT 'include',_include,_include.dict
	DICT '(include)',__include,__include.dict
	DICT 'eval',eval,eval.dict
	DICT 'parse',parse,parse.dict
	DICT 'parse/',parse_with_escape,parse_with_escape.dict
	DICT 'forth',_forth,_forth.dict, mclass
	DICT 'macro',_macro,_macro.dict, mclass
	DICT 'appname',appname,appname.dict,cclass
	DICT '(save)',_save,_save.dict
	DICT "(.r)",_printr,_printr.dict
	DICT 'link', link, link.dict
	DICT '-link', link2, link2.dict
	DICT 'iterate', iterate, iterate.dict
	DICT 'slurp',_slurp,_slurp.dict

align 4
NONBSS
flast dd mylink ; last word in dictionary
VARNEW last,flast

VARNEW h, _h0
VARNEW d,_d0		;
__start dd 0
__exit dd 0
handler dd 0
static_size = $-static_start
align 4
rb 8

VARNEW is_compiling
VARNEW __ior
VARNEW default_class,fclass
VARNEW padchar,32
VARNEW base,10
VARNEW source
VARNEW tin
VARNEW StdOut
VARNEW StdIn
VARNEW hinstance
VARNEW tp,tib
VARNEW s0,_s0
VARNEW d0,_d0
VARNEW h0,_h0
VARNEW _os, OS
VARNEW _tib, tib
VARNEW _pad, __pad
VARNEW appname, app_file_name
VARNEW __str0, _str0
VARNEW rp0, _rp0
VARNEW nosavedict
;VARNEW argc
align 4
argc dd 0

; ----------------------------------------------------------------------
; ( c -- n ) -- convert character to digit
; ----------------------------------------------------------------------
; This table is used for converting an input character to a digit.  Some special 
; flags are also here: -3 means invalid character (in a number).  80h means NOP 
; - ignore the character, and 80h+xxx means switch to base xxx
align 4
fromdigits:
;    0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
db 00h, 01h, 02h, 03h, 04h, 05h, 06h, 07h, 08h, 09h,  -1,  -1,  -1,  -1,  -1,  -1  ;3
db  -1, 0ah, 0bh, 0ch, 0dh, 0eh, 0fh, 10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h, 18h  ;4
db 19h, 1ah, 1bh, 1ch, 1dh, 1eh, 1fh, 20h, 21h, 22h, 23h,  -1,  -1,  -1,  -1,  -1  ;5
db  -1, 0ah, 0bh, 0ch, 0dh, 0eh, 0fh, 10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h, 18h  ;6
db 19h, 1ah, 1bh, 1ch, 1dh, 1eh, 1fh, 20h, 21h, 22h, 23h  ; ,  -1,  -1,  -1,  -1,  -1  ;7
align 4
digits db '0123456789ABCDEF'
align 4
bases db 10,16,2,8,255

; ----------------------------------------------------------------------
; END PERSISTED STATICS
; ----------------------------------------------------------------------

; ----------------------------------------------------------------------
; BSS SECTION
; ----------------------------------------------------------------------
align 4
BSS
align 4
bss_size = $-bss_start
_h0  rb CODESIZE		; Code 
_htop:

_npad:
tempX rd 2		; temp vars
_rp0 rd 1
do_tail rd 1
app_file_name	rb 256
lasth rd 1
lastd rd 1
lastl rd 1
;environ rd 1
argv rd 1
slurpy rd 1
slurpySize rd 1
align 4
tib rb TIBSIZE		; Text Input Buffer (1k)
tibtop:
__pad rb PADSIZE
 rd 16	; underflow area.
    rd STACKSIZE	; Stack (2k normal)
_s0  rd 1
 rd 16	; underflow area.
save_header:
	; These are sanity-check values:
	sh_sig rd 1		; initial signature
	; These are data-size values:
	sh_ssz rd 1		; static data size
	sh_bsz rd 1		; bss data size
	sh_hsz rd 1		; code size
	sh_dsz rd 1		; dict size
	; uncompressed size =
	;  sh_ssz + sh_bsz + sh_hsz + sh_dsz

	; These are tail-sanity-check values:
	sh_total rd 1		; total actually written out
	sh_sig2 rd 1		; final signature for sanity-check

	; These are for compression and decompression:
	sh_size rd 1
	sh_ptr1 rd 1		; uncompressed data
	sh_ptr2 rd 1		; compressed data

	rb 256

align 4
_str0 rb STRSIZE		; interpret-mode strings
 align 4 
_d0  rb DICTSIZE		; Dictionary 
_dtop:

blz_limit rd 1
blz_bkptr rd 1
_blz_filebuf rb 128*1K		; for 'slurp'ing the file
_blz_buf rb (DICTSIZE + STRSIZE + DICTSIZE )
blz_workmem rb BLZ_WORKMEM_SIZE
parse_buf rb 128*1K
fzt_buf rb 512
