@echo off
cd bin
del reva.exe
del revacore.exe
cd ..
cd src
echo Building revacore
 fasm corewin.asm ..\bin\revacore.exe
echo Building Reva
 ..\bin\revacore.exe reva.f
cd ..
echo Building help file
bin\reva.exe bin\genhelp.f
echo Running test suite
bin\reva.exe bin\test.f
