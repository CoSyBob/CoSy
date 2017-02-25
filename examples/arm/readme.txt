Arm target compiler  24-Feb-07

This is a target compiler for the windows mobile based pocketpc (ppc). It does not run on the ppc
as such. Instead, it generates arm compatible exe images of your application which can then be 
downloaded and run on the ppc.
Initially the application is written, tested, and debugged in the normal reva environment on the 
desktop. Then it is reconfigured (by defining the word 'arm' at the start of the application) 
to generate the arm exe file. Hopefully this will run on the ppc :)
Try the two examples (files 6 and 7 below) to get a feel for how this all works.
These two examples run fine on my Dell Axim ppc running windows mobile 2003, but I make no guarantees
about other ppcs.
 

The armtc.f file makes an ~arm context which redefines many of the words in the standard
reva vocabulary. These are the words that are used to make the arm application. The ~arm context
is kept on top of the search order so that these words will be found first. The ~arm context
currently contains about 150 standard reva words, but it is not a complete set!!!!
This means that if you use a word that is not in the ~arm context, the reva compiler will find it
in a lower context and compile it in to your app without any error message. THIS WILL THEN CRASH
ON THE PPC. YOU HAVE BEEN WARNED!!!. 
You can check which words are available by loading the armtc.f library (needs /arm/armtc.f) then 
typing 'words' at the prompt.


Files:-

1. armtc.f        - the arm target compiler library

2. armwinhdr.f    - header file for arm/windows applications.

3. armasm         - arm assembler library. Requires FASMARM.exe

4. armimg.exe     - arm image file which forms the basis of the final application executable.

5. armimg.asm     - source code for above. (Not normally used.)

6. armapp.f       - a simple example (Hello world) application

7. armlife.f      - a more advanced example. Implements John Conway's "game of life"

8. readme.txt     - this file

9. armapp.exe     - compiled version of armapp.f. Should run on ppc

10. armlife.exe   - compiled version of armlife.f. Should run on ppc
 
Files 1 -> 5 should be placed in reva/lib/arm (you will need to make the /arm subdirectory)
The two example applications can go in a directory of your choice (eg reva/armprojects/)

Also required is the flat assembler for the arm cpu, FASMARM.EXE which is not included. It can be
downloaded from http://arm.flatassembler.net/.
You just need the Win32 package which contains FASMARM.EXE. This should be placed in your reva 
directory.

Both examples will run on either the desktop or on an arm-based pocket pc, depending on whether the
word 'arm' is defined at the start of the file. If 'arm' is defined, an arm compatible exe file will
be created (called armapp.exe) in the current directory. This can be downloaded to the ppc (using
ActiveSync) and run by clicking on it with the stylus.

This has been a big project for me and is by no means complete. I'm posting it as is to see how
much interest there is, and to get suggestions and perhaps some help to advance it further.

