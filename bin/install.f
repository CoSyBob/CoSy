needs os/console
black white color
: bred red bold fg ; 
: blk black fg ;
cls
." Welcome to the " bred .ver  blk ."  installer!" cr
cr cr

os [IF]
create procname 255 allot
create proclink 255 allot
85 constant linux_readlink
: has/proc? 
	" /proc/" procname place
	getpid (.) procname +place
	" /exe" procname +place
	procname count open/r dup 0 >if close else 
	." Because of your system's setup, you MUST use the full path to" cr
	." Reva in order for it to work properly" cr
	then ;

has/proc?

	." There is nothing to 'install' on Linux.  You may want to add" cr
	'" emit bred appdir type blk '" emit ."  to your $PATH" cr
[ELSE]
needs os/registry
with~ ~registry
needs string/trim

value hreg
variable isnt
u32 drop 
4 func: SendMessageA
26 constant WM_WININICHANGE

: yesno ekey lc 'y <>if cr ." Bye!" blk cr bye then ;
: installed? 
	HKCU " Software\\Reva" openkey to hreg  
	hreg if 
		pad off
		hreg 0L pad 255 queryvalue
		hreg closekey
		pad zcount revaver cmp 0if
			." This version of Reva has already been installed.  Reinstall? "
			yesno cr
		else
			| a prior version of Reva has been installed.
		then
	then
	;

installed?
." This will install Reva, making a desktop shortcut and an Explorer association" cr
bred ." Do you want to continue?" blk yesno
cr
." Creating appropriate registry entries..." cr

| Are we on NT?
HKLM " SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion" openkey to hreg  
hreg isnt !
hreg closekey

HKCR " .f" createkey to hreg
hreg 0L REG_SZ " reva_auto_file" setvalue
hreg closekey

appname zcount scratch lplace
"  \"%1\"" scratch +lplace

create scratch2 8000 allot 
HKCR " reva_auto_file\\shell\\open\\command" createkey to hreg 
hreg 0L REG_SZ scratch lcount setvalue
hreg closekey

HKCR " Applications\\reva.exe\\shell\\open\\command" createkey to hreg 
hreg 0L REG_SZ scratch lcount setvalue
hreg closekey

HKCU " Software\\Reva" createkey to hreg 
hreg 0L REG_SZ revaver setvalue
hreg closekey

variable newpath
: cleanpath ( a n -- )
	'; split >r
	
	2dup " reva" search if 
		2drop 2drop 
	else 
		newpath @ @ if '; newpath @ c+lplace then
		newpath @ +lplace
	then

	r> 0; drop cleanpath 
	;
: setpath
	isnt @ if 
		| WinNT
		" PATH" getenv dup 5 + allocate dup off newpath ! 
		cleanpath
		| scratch lcount type cr
		HKCU " Environment" createkey to hreg 
		hreg " path" REG_EXPAND_SZ newpath @ lcount trim 1+ setvalueex
		hreg closekey
		newpath @ free
		| Tell NT we changed the environment:
		-1 WM_WININICHANGE 0 " Environment" zt SendMessageA
		." Please start another command-shell so the changes to %PATH% will take effect"
	else
		| Win9x - have to write to the autoexec.bat
		" PATH=%PATH%;" scratch place
		appdir 1- scratch +place
		" c:\\autoexec.bat" open/rw ioerr @ if 
			drop " c:\\autoexec.bat" creat
		then
		| seek to end-of-file
		dup fsize over seek
		dup scratch count rot write close
		." You will need to reboot so the changes to %PATH% will take effect"
	then
	;
setpath
cr

[THEN]

bred ." Done installing." blk cr

cr 
." Please read the README file for more details." cr
." When you run Reva, you can get help by just typing " bred ." help" blk cr cr
." Enjoy Reva!" cr bye
