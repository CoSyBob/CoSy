;;
;; BriefLZ  -  small fast Lempel-Ziv
;;
;; NASM small assembler packer
;;
;; Copyright (c) 2002-2004 by Joergen Ibsen / Jibz
;; All Rights Reserved
;;
;; http://www.ibsensoftware.com/
;;
;; This software is provided 'as-is', without any express
;; or implied warranty.  In no event will the authors be
;; held liable for any damages arising from the use of
;; this software.
;;
;; Permission is granted to anyone to use this software
;; for any purpose, including commercial applications,
;; and to alter it and redistribute it freely, subject to
;; the following restrictions:
;;
;; 1. The origin of this software must not be
;;    misrepresented; you must not claim that you
;;    wrote the original software. If you use this
;;    software in a product, an acknowledgment in
;;    the product documentation would be appreciated
;;    but is not required.
;;
;; 2. Altered source versions must be plainly marked
;;    as such, and must not be misrepresented as
;;    being the original software.
;;
;; 3. This notice may not be removed or altered from
;;    any source distribution.
;;
    ; blz_pack(const void *source,
    ;          void *destination,
    ;          unsigned int length,
    ;          void *workmem);
; Reva notes:
macro FNVHASH {
	push ecx
	push edx
	push ebp
	push ebx
	mov ecx, 4
	mov ebx, esi
	call fnvhash.0
	pop ebx
	pop ebp
	pop edx
	pop ecx
        and eax, (BLZ_WORKMEM_SIZE/4)-1
}
; workmem is a global bss -> "blz_workmem"
; ( insize -- maxsize )
PROC blz_maxsize
	mov ebx, eax
	sar ebx, 3
	add eax, ebx
	add eax, 64
	ret
ENDP blz_maxsize

; ( src srcn dest -- dest destn | 0 0 )
PROC blz_pack
	; zero out the lookuptable:
	upsh blz_workmem
	upsh BLZ_WORKMEM_SIZE
	upsh 0
	call _fill

	; set up pointers to the data:
	upop edi	; dest ptr
	upop ebx	; src len
	; EAX -> src ptr.  we'll use ESI, and just save our current ESI
	push edi
	push esi
	mov esi, eax
	; ESI->src EDI->dst, EBX->count
	; save the initial dest ptr away:
	
;    mov    esi, [esp + .src$]
;    mov    edi, [esp + .dst$]
;    mov    ebx, [esp + .len$]

    lea    eax, [ebx + esi - 4]
    mov [blz_limit], eax
;    mov    [esp + .lim$], eax ; limit = source + length - 4

	mov [blz_bkptr], esi
;    mov    [esp + .bpt$], esi ; backptr = source

    test   ebx, ebx           ; length == 0?
    jz     .jmptodone   ;

    movsb                     ; fist byte verbatim

    cmp    ebx, 1        ; only one byte?
.jmptodone:                 ;
    je     near .EODdone      ;

    xor    ebp, ebp           ; initialise tag
    inc    ebp                ;
    mov    edx, edi           ;
    add    edi, 2        ;

    jmp    .nexttag

.no_match:
    clc
    call   putbit             ; 0-bit = literal

    movsb                     ; copy literal

.nexttag:
    cmp    esi, [blz_limit]	; esp + .lim$] ; are we done?
    jae    .donepacking ;

    mov    ecx, blz_workmem	; [esp + .wkm$] ; ecx -> lookuptable[]

    mov    ebx, esi           ; ebx = buffer - backptr
    xchg   esi, [blz_bkptr]	; [esp + .bpt$] ; i.e. distance from backptr to current
    sub    ebx, esi           ; (also stores new backptr)

.update:
;    call   hash4              ; hash next 4 bytes
	FNVHASH

    mov    [ecx + eax*4], esi ; lookuptable[hash] = backptr

    inc    esi                ; ++backptr
    dec    ebx
    jnz    .update      ; when done, si is back to current pos

;    call   hash4              ; hash next 4 bytes
	FNVHASH

    mov    ebx, [ecx + eax*4] ; ebx = lookuptable[hash]

    test   ebx, ebx           ; no match?
    jz     .no_match    ;

    ; check match length
    mov    ecx, [blz_limit]	;[esp + .lim$] ; ecx = max allowed match length
    sub    ecx, esi           ;
    add    ecx, 4        ;

    push   edx

    xor    eax, eax
.compare:
    mov    dl, [ebx + eax]    ; compare possible match with current
    cmp    dl, [esi + eax]    ;
    jne    .matchlen_found

    inc    eax

    dec    ecx
    jnz    .compare

.matchlen_found:
    pop    edx

    cmp    eax, 4        ; match too short?
    jb     .no_match    ;

    mov    ecx, esi           ;
    sub    ecx, ebx           ; ecx = matchpos

    call   putbit1            ; 1-bit = match

    add    esi, eax           ; update esi to next position

    sub    eax, 2        ; matchlen >= 4, so subtract 2

    call   putgamma           ; output gamma coding of matchlen - 2

    dec    ecx                ; matchpos > 0, so subtract 1

    mov    eax, ecx           ; eax = (matchpos >> 8) + 2
    shr    eax, 8             ;
    add    eax, 2        ;

    call   putgamma           ; output gamma coding of (matchpos >> 8) + 2

    xchg   eax, ecx           ; output low 8 bits of matchpos
    stosb                     ;

    jmp    .nexttag

.donepacking:

    mov    eax, [blz_limit]	;[esp + .lim$] ; ebx = source + length
    lea    ebx, [eax + 4]     ;

    jmp    .check_final_literals

  .final_literals:
    clc
    call   putbit             ; 0-bit = literal

    movsb                     ; copy literal

  .check_final_literals:
    cmp    esi, ebx
    jb     .final_literals

    test   ebp, ebp           ; do we need to fix the last tag?
    jz     .EODdone     ;

  .doEOD:
    add    bp, bp             ; shift last tag into position
    jnc    .doEOD       ;

    mov    [edx], bp          ; and put it into it's place

  .EODdone:
    pop    esi
    pop    eax	;		original ptr
    dup
    sub    eax, edi ; blz_limit[esp + .dst$] ;
    neg eax
    ret

; =============================================================

putbit1:                      ; add 1-bit
    stc
putbit:                       ; add bit according to carry
    dec    ebp
    jns    .bitsleft
    mov    edx, edi
    inc    edi
    inc    ebp
    inc    edi
.bitsleft:
    inc    ebp
    adc    bp, bp		; is this reall correct?
    jnc    .done
    mov    [edx], bp
    xor    ebp, ebp
.done:
    ret

putgamma:                     ; output gamma coding of value in eax
    push   ebx                ; (eax > 1)
    push   eax
    shr    eax, 1
    xor    ebx, ebx
    inc    ebx
.revmore:
    shr    eax, 1
    jz     .outstart
    adc    ebx, ebx
    jmp    .revmore
.outmore:
    call   putbit
    call   putbit1
.outstart:
    shr    ebx, 1
    jnz    .outmore
    pop    eax
    shr    eax, 1
    call   putbit
    call   putbit             ; CF = 0 from call above
    pop    ebx
    ret
ENDP blz_pack

; unpack
; =============================================================
    ; blz_depack(const void *source,
    ;            void *destination,
    ;            unsigned int depacked_length);

; ( src srcn dest -- dest' destn' | 0 0 )

PROC blz_depack
    .len$  = 3*4 + 4 + 8
    .dst$  = 3*4 + 4 + 4
    .src$  = 3*4 + 4
    upop edi	; dest
    push edi
    upop ebx	; length
    ; eax is src
    push esi
    mov esi, eax
    xor    edx, edx           ; initialise tag
    add    ebx, edi           ; ebx = destination + length

  .literal:
    movsb                     ; copy literal

  .nexttag:
    cmp    edi, ebx           ; are we done?
    jae    .donedepacking

    call   .getbit            ; literal or match?
    jnc    .literal     ;

    call   .getgamma          ; ecx = matchlen
    xchg   eax, ecx           ;

    call   .getgamma          ; eax = (matchpos >> 8) + 2

    dec    eax                ; eax = (matchpos >> 8)
    dec    eax                ;

    inc    ecx                ; matchlen >= 4, so add 2
    inc    ecx                ;

    shl    eax, 8             ; eax = high part of matchpos
    lodsb                     ; add low 8 bits of matchpos

    inc    eax                ; matchpos > 0, so add 1

    push   esi

    mov    esi, edi           ; copy match
    sub    esi, eax           ;
    rep    movsb              ;

    pop    esi

    jmp    .nexttag

.getbit:                    ; get next tag-bit into carry
    add    dx, dx
    jnz    .stillbitsleft
    xchg   eax, edx
    lodsw
    xchg   eax, edx
    add    dx, dx
    inc    edx
.stillbitsleft:
    ret

  .getgamma:                  ; gamma decode value into eax
    xor    eax, eax
    inc    eax
  .getmore:
    call   .getbit
    adc    eax, eax
    call   .getbit
    jc     .getmore
    ret

  .donedepacking:
    pop    esi
    pop eax	; old edi
    dup
    sub eax, edi
    neg eax

    ;xchg   eax, edi           ; return unpacked length in eax
    ;sub    eax, [esp + .dst$] ;
	ret
ENDP blz_depack
