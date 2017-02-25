| example of how to use the asm{ word

needs asm

: tstasm
    cr ." TOS is: " dup .   | normal forth words
    |  use only assembly (fasm compatible) code between the braces
    asm{
    add eax, 1000   ; add 1000 to tos
    inc eax         ; add 1 to tos
    inc eax         ; add 1 to tos
    }

    cr ." Now it is: " . | more normal forth
    ;

10 tstasm
