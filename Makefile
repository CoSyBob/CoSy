ifeq ($(MSYSTEM),MINGW32)
PARENT=../
REVA=bin/reva
else
ifeq ($(OS),Windows_NT)
REVA=bin\reva$(EXE)
PARENT=..\\
else
PARENT=../
REVA=bin/reva
endif
endif

BENCH=.

reva: $(REVA)

$(REVA): src/reva.f src/revacore.asm src/corewin.asm src/corelin.asm src/brieflz.asm \
	src/macros src/reva.res src/reva.ico
	@make -C src --no-print-directory

win:
	@make -C src --no-print-directory $(PARENT)bin/reva.exe

lin:
	@make -C src --no-print-directory

both: lin win

bin/help.db: src/help.txt
	@echo Building help file
	@$(REVA) bin/genhelp.f

docs: $(REVA) src/help.txt bin/help.db 

check: docs
	$(REVA) bin/checkhelp.f

clean:
	@rm -f bin/reva bin/reva.exe

realclean: clean
	@rm -f bin/revacore bin/revacore.exe
	@rm -f bin/help.db

test: $(REVA)
	@$(REVA) bin/test.f

all: docs test

dist: realclean both docs test
	@$(REVA) bin/dist.f

bench: $(REVA)
	@(cd $(BENCH)/bench && $(PARENT)$(REVA) bench.f)

tags:
	@ctags -R src examples --language-force=reva lib
