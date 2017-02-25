
| computer language shootout
| http://shootout.alioth.debian.org/
| contributed by albert van der horst, ian osgood
| modified for Reva http://ronware.org/reva/ 
| by Ron Aaron

: .ms 1000 /mod (.) type '. emit 3 '0 (p.r) type space ;
needs math/big
with~ ~bigmath
| read num from last command line argument:
: getnum argc argv >single 0if 2drop 10 then ;
getnum constant num

|
| pi-spigot specific computation
|

| counters:
variable D
variable I
variable N
| Temporary numbers U,V,W
big: U
big: V
big: W
| Transformation matrix: [Q,R,S,T]
1 big!: Q
big: R
big: S
1 big!: T
| accumulated digits for one line: 
create digits 10 allot

0 [IF]
/* Compose matrix with numbers on the right. */
void compose_r(ctx_t* c, int bq, int br, int bs, int bt)
{
    mpz_mul_si(c.u, c.r, bs);
    mpz_mul_si(c.r, c.r, bq);
    mpz_mul_si(c.v, c.t, br);
    mpz_add(c.r, c.r, c.v);
    mpz_mul_si(c.t, c.t, bt);
    mpz_add(c.t, c.t, c.u);
    mpz_mul_si(c.s, c.s, bt);
    mpz_mul_si(c.u, c.q, bs);
    mpz_add(c.s, c.s, c.u);
    mpz_mul_si(c.q, c.q, bq);
}

/* Compose matrix with numbers on the left. */
void compose_l(ctx_t* c, int bq, int br, int bs, int bt)
{
    mpz_mul_si(c.r, c.r, bt);
    mpz_mul_si(c.u, c.q, br);
    mpz_add(c.r, c.r, c.u);
    mpz_mul_si(c.u, c.t, bs);
    mpz_mul_si(c.t, c.t, bt);
    mpz_mul_si(c.v, c.s, br);
    mpz_add(c.t, c.t, c.v);
    mpz_mul_si(c.s, c.s, bq);
    mpz_add(c.s, c.s, c.u);
    mpz_mul_si(c.q, c.q, bq);
}
[THEN]
| Extract one digit
: extract ( n -- m )
	>r	| "J"
	U Q r@ big*n	| mpz_mul_ui(c.u,c.q,j)
	U U R big+		| mpz_add(c.u,c.u,c.r)
	V S r> big*n	| mpz_mul_ui(c.v,c.s,j)
	V V T big+		| mpz_add(c.v,c.v,c.t)
	W U V big/		| mpz_tdiv_q(c.w,c.u,c.v)
	W big>int
	;

| print one digit, return 1 for last digit
: prdigit ( y -- n )
	'0 + D digits + c!
	D ++ 
	I @ 1+ dup I !	| I
		dup
		10 mod 0if
		swap N @ = or
			| ten digits calculated or end of desired digits reached:
			digits 10 type space I . cr
			D off
		then
	I @ N @ = abs
	;

| spigot n digits with formatting
variable k
: spigot ( digits -- ) 
	1 k !
	repeat
		| y = extract(c,3)
		3 extract
		dup 
		| if y == extract(c,4)
		|    if (prdigit(c,y)) return;
		|    compose_r(c,10,-10*y,0,1);
		| else
		|    compose_l(c,k,4*k+2,0,2*k+l);
		|    k++

	again
	;
	| 2dup 10 - do .digit loop  over - spaces  .count ;
ms@
num spigot 
ms@ swap - .ms
bye
