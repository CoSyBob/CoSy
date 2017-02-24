( dllexplore.f )
( written by peter hart on friday 30 march 2007 )
hex

: v dup 100 + swap 100 dump ;

variable image-base

: beep 7 emit ;

: setimagebase   image-base ! ;   ( image base --- )

: setup k32 setimagebase hex ;

' setup onstartup

: offset-to-signature   image-base @ 3c + @ ffff and ; ( --- offset )

: signature offset-to-signature   image-base @ + ; ( --- signature address )

: optional-header   signature 18 + ; ( --- optional header address )

: magic   optional-header @ ffff and ; ( --- magic number )

: normal   magic 10b = ; ( --- flag )

: 64bit   magic 20b = ; ( --- flag )

: rom-image   magic 107 = ; ( --- flag )

: export-table  ( --- export table address )
    0   | returned if all else fails
    normal if
        drop optional-header 60 + @ image-base @ +
    else
        64bit if
            drop optional-header 70 +  @ image-base @ +
        then
    then
    ;

: dll-name   export-table c + @ image-base @ + ;   ( --- dll name address )

: ordinal-base export-table 10 + @  ; ( --- first ordinal number )

: number-of-entries-in-address-table ( --- number of entries in address table)
    export-table 14 + @ ;

: number-of-name-pointers    ( --- number of name pointers )
    export-table 18 + @ ; 

: export-address-table   ( --- address of export address table )
    export-table 1c + @ image-base @ + ;

: name-pointer-table   ( --- address of table of name pointers )
    export-table 20 + @ image-base @ + ;

: ordinal-table   ( --- address of ordinal table )
    export-table 24 + @ image-base @ + ;

: crude-string-display ( address --- ) 
    23 type ;

: show-function-names ( --- )
    number-of-name-pointers 0 do
        name-pointer-table i 4 * + @ image-base @ +
        cr crude-string-display
    loop ;

: identify-function   ( ordinal --- )
     dup .
     ordinal-base -  dup
     4 * name-pointer-table + @ image-base @ + crude-string-display 3 spaces
     4 * export-address-table + @ dup . image-base @ + .
     ;

save pogo.exe

save explore-dll.exe

|||

The specification used for this work is a Word document
pecoff_v8.doc

The program PEBrowse Professional was also very helpful.

In Reva Forth there is a word k32 that gives the address of kernel32.dll.
This dll is my main interest, and was also used as a guinea pig for
testing this program.

My purpose is to find the addresses of dll functions so that I can
call them from Forth programs.

I still need to learn how to pass parameters and handle returns
when calling the functions.

=======================================================

In a Portable Executeable file:

At offset 0 the initials MZ appear.

At offset 3c there is the offset to the signature.

The signature is PE\0\0

After the signature there is a COFF file header of 20 bytes
(see section 3.3 of the specification)

        Offset within
        COFF File header        Size    Purpose

                0               2       Machine
                2               2       Number of sections
                4               4       Date/Time stamp
                8               4       Pointer to symbol table
                                        ( 0 for image file )
               12               4       Number of symbols
                                        ( 0 for image file )
               16               2       Size of 'optional' header
                                        ( 0 for object file )
               18               2       Characteristics

Right after the COFF header (at signature address + 0x18)
is the 'optional' header required for an image file.
(see section 3.4.1 of the specification)

        At offset 0 in the optional header file there is
        a two-byte magic number indicating the type of fille

            VALUE               MEANING

            0x10B               Normal PE32 file (32 bit)
            0x20B               PE32+            (64 bit)
            0x107               ROM image

        At offset 96 decimal (for a PE32 file) or
        at offset 112 decimal (for a PE32+ file)
        there is the RVA (offset from start of image)
        of the export table.

This is the format of the Export Table
(see section 6.3.1 of the specification)

        Offset in
        Export table    Size    Purpose

                0       4       Flags, reserved, = 0
                4       4       date/time stamp
                8       2       major version
               10       2       minor version
               12       4       RVA of name of file
               16       4       Ordinal base (usually 1)
               20       4       Number of entries in address table
               24       4       number of name pointers
               28       4       RVA of export address table
               32       4       RVA of name pointer table
               36       4       RVA of ordinal table

