#! bin/reva

os not [IF] ." Must build on Linux, sorry." cr bye [THEN]

needs os/shell
needs string/misc

create pad2 256 allot
create zippy 10000 allot
: zipname 
	pad2 c@ 0if
		" reva" pad2 place 
			revaver# 256 /mod 256 /mod
				 (.) pad2 +place
				 (.) pad2 +place
				 (.) pad2 +place
		" .zip" pad2 +place
	then
	pad2 count 
	;
: zip " cd .. && zip -9qr " zippy lplace zipname zippy +lplace
	32 zippy c+lplace
	parseln zippy +lplace
	zippy lcount shell 
	;

| ." Building the binaries" cr
| !! build clean all && build all && build docs
." Building distribution file: " zipname type cr 

" ../" zipname strcat delete
" src/linux.o" delete 
" src/asm.err" delete

!! unix2dos -D build.bat install.bat bin/bench.bat
zip -i@reva/include.lst -x@reva/exclude.lst reva/*
| zip reva/Makefile reva/README reva/CREDITS reva/LICENSE reva/THANKS! reva/install.bat reva/install.sh reva/build.bat reva/build `find reva/bin reva/lib reva/examples reva/contrib reva/src reva/bench| grep -v CVS | grep -v ".svn"`
." Generating signatures:" cr
" cd .. && gpg --detach-sign -a " zipname strcat " && md5sum " strcat zipname strcat shell
bye
