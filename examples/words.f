| Sample which dumps all words in a format to be pasted into the Wiki:
| Words are sorted
with~ ~priv  | all-contexts

| marker to indicate end-of-internal-words
variable $$$$

needs alg/hsort
:: ( a1 a2 -- f )	
	count rot count cmpi
	0 >
	; is compare
create wordlist 1000 cells allot
: clearlist wordlist off ;
variable process?
: processing?
	dup c@ if
		process? @ 0if
			[''] $$$$ <if
				process? on
			then
			false
		else
			drop true
		then
	else drop false then
	;
: makelist ( ctx -- )
	process? off
	| last xchg >r	| r:old-last
    last @ >r
    @ last !
	wordlist cell+	| first element to put items in
	| iterate over the *list* and put the names into the array:
    {	
		cell- >name dup processing? 
		if over ! cell+ wordlist ++ else drop then
		true
		}
    last iterate 
	r> last ! 
	;
: sortlist wordlist lcount hsort ;
: printlist wordlist lcount dup ."  (" . ." words)<br><tt><nowiki>" cr
	0do 
		dup 
		@ count type space 
		cell+
	loop
	drop
	cr ." </nowiki></tt>" cr
	;
: listwords ( ctx -- ) clearlist makelist sortlist printlist cr cr ;
: dumpwords ( -- )
	{ 
		@ 
		." ----" cr
		." context: '''" dup ctx>name type ." '''" 
        listwords 
		true
	} all-contexts iterate
	;

." <center>'''Comprehensive list of words in Reva " revaver type ." '''</center><br>"cr
." <center>Produced by [[words.f]]</center>" cr cr
dumpwords bye
