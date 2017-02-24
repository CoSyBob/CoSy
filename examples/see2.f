| see2 lets you see a disassembly of the code snippet which follows:
|
|   see2 1
|
| will display something like:
|   lea esi, [esi-04]
|   mov [esi], eax
|   mov eax, 00000001
|   ret


needs debugger

macro 
: see2 ( <code> -- n )
	" { " pad place parseln pad +place "  }" 
	pad +place 
	here pad count eval 
	swap here swap - tuck disassemble negate allot ;
forth

