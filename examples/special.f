| demonstration of special settings overrides:

| We want "~sys" to be in the search order:

: reva reset~ ~reva ~sys ~os ~util ~io ~strings ~ ; reva

' reva onstartup

| Make the prompt unique:
:: .s cr ." >> " ; is prompt

| Funky code to save "special" on linux, and "special.exe" on windows:
." Creating 'special' program..."
" special" makeexename (save) bye
