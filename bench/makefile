everything=reva 501 60 gforth gforth-fast benchc benchc2
REVA=..$(VERSION)/bin/reva

reva: 
	@echo $(VERSION)
	$(REVA) bench.f

60: VERSION=/reva600
60: reva

501: VERSION=/reva501
501: reva

601: VERSION=/reva601
601: reva

603: VERSION=/reva603
603: reva

606: VERSION=/reva606
606: reva

607: VERSION=/reva607
607: reva

ifeq ($(windir),)
GF=gforth
BENCHC=benchc
else
everything+=w32f
GF=\gforth\gforth
W32F=/Program Files/Win32Forth/Win32For
w32f:
	@$(W32F) include bench-w32f.f

BENCHC=benchc.exe
endif
gforth:
	@echo "gforth:"
	$(GF) bench-gf.f
gforth-fast:
	@echo "gforth-fast:"
	@$(GF)-fast bench-gf.f

benchc: $(BENCHC)
	@echo "bench-c:"
	@$(BENCHC)
benchc2: fast$(BENCHC)
	@echo "fastbench-c:"
	@fast$(BENCHC)

$(BENCHC): bench-c.c
	@gcc -o $(BENCHC) $<
fast$(BENCHC): bench-c.c
	@gcc -o fast$(BENCHC) -O2 $<

all: $(everything)
