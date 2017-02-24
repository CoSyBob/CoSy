@echo off
setlocal

:again
	set who=%1
	if "%1"=="" set who=.
	shift
	gosub bench
	if "%1"=="" goto done
	goto again

:bench
	cd %who%\bench
	shift
	..\bin\reva bench.f
	cd ..
	return

:done
