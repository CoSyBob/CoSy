ifeq ($(OS),Windows_NT)
EXE=.exe
WINE=
target: ../bin/reva.exe
else
EXE=
WINE=wine
target: ../bin/reva
endif

SRC=reva.f brieflz.asm revacore.asm macros reva.res reva.ico

../bin/reva.exe: ../bin/revacore.exe reva.f
	@$(WINE) ../bin/revacore.exe reva.f
	
../bin/revacore.exe: corewin.asm $(SRC)
	@fasm corewin.asm $@

../bin/reva: ../bin/revacore reva.f
	@../bin/revacore reva.f
	
../bin/revacore: corelin.asm $(SRC)
	@fasm corelin.asm linux.o
	@gcc -o $@ -ldl -s -nostartfiles linux.o
	@strip $@

# The no-gcc-required Linux core:
corenew: corelin-new.asm $(SRC)
	@fasm $< $@
	@chmod +x $@
