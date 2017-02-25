| The Great Computer Language Shootout
| http://shootout.alioth.debian.org/
|
| contributed by Ian Osgood
| NOTE: must run gforth with flags "-m 8M" for NUM = 9
|
| Modified for Reva by Ron Aaron

| read NUM from last command line argument
: getnum argc argv >single 0if 2drop 10 then ;
getnum constant num

: bufsize 1 swap << 10000 * ;
num bufsize allocate value buf
: sieve ( size -- n )
	buf over 1 fill
	0 over 2 do
		buf i + c@ if 
			1+ over buf + buf i 2* + over min ?do
				0 i c!
				j 1- skip 
				loop
		then
	loop nip ;

| count primes up to 2^n*10000
: test ( n -- )
  bufsize
  ." Primes up to " dup 8 .r sieve 9 .r cr ;

| run sieve for N, N-1, N-2
  num test  num 1- test  num 2 - test

bye  \ done!

