| convert help.txt to help.db

~sys
needs string/trim
needs db/sqlite
needs os/dir
~db
~
0 value db
create currentlib 10 allot
false value verbose
create langbuf 16 allot			| name of language
create wordbuf 256 allot		| name of word
create stackbuf 256 allot		| stack diagram
create origbuf 256 allot		| origin of word
create origbuf2 10 allot
create ctxbuf 256 allot			| context of word
create osbuf 256 allot			| os this appears in (blank =both, or linux or windows)
create descbuf 10000 allot		| description of word
create verbuf 256 allot			| version of Reva this word first appears
create buf 10000 allot			| the SQL to write out
create enq	10000 allot

: null? dup c@ 0if drop " NULL" else count then ;
: notnull! dup c@ 0if wordbuf count type ."  is incomplete" cr -1 throw ;then count ;
: -cr ( a n -- )
	00; 2dup 0do
		count 
		13 =if 32 over 1- c! then
	loop drop
	;

: enquote ( a n -- a' n' )
	-cr
	" '" enq lplace
	quote' enq +lplace
	39 enq c+lplace
	enq lcount
	;
: ,, ', buf c+lplace ;

: nocr 2dup + c@ 13 =if 1- then ;
| trim is bad ?!?
: getline parseln trim enquote ;
: stack: ( <stack> )
	getline stackbuf place 
	;

::	cr type_ ." not found in file: "
	origbuf count type cr bye
	; is word?
: doorig
	" insert into orig values(NULL, " pad place
	origbuf count pad +place
	" )" pad +place 
	db pad count sql_exec
	" select ix from orig where name=" pad place
	origbuf count pad +place
	db pad count sql_fetch$
	origbuf2 place
	;
: orig: ( <stack> ) getline origbuf place doorig ;
: ctx: ( <context> ) getline ctxbuf place ;
: os: ( <os> ) getline osbuf place ;
: ver: ( <os> ) getline verbuf place ;
: edx>eax inline{ 89 D0 } ;
: 'language | class of 'lang:' words
	edx>eax	| get the dict ptr.  BAD: relies on internals of the compiler
	>name count langbuf place
	; newclass
: lang: ( <[xx]> ) parseln (header) p: ;
	['] 'language last @ >class !
	;

: getix ( a n -- ix )
	trim
	dup 0if 2drop 0 ;then
	" select ix from help where word=" pad place
	enquote pad +place
	db pad count sql_fetch# ;


create first 20 allot
create second 20 allot
: dopermute ( -- )
	db " insert into also values (" pad place
		first count pad +place
		" ," pad +place
		second count pad +place
		" )" pad +place  
		pad count sql_exec
	db " insert into also values (" pad place
		second count pad +place
		" ," pad +place
		first count pad +place
		" )" pad +place  
		pad count sql_exec
	;
: permute ( ... n -- )
	1- 0drop; 0do
		| take the top item and each of the following items and permute:
		(.) first place
		remains 1+ 0do
			i pick (.) second place dopermute
		loop
	loop
	drop
	;

: related ( a n -- )
	verbose if ." related: " 2dup type cr then
	?dup 0if drop ;then
	trim
	| split the string into component words.  Keep track of how many words have
	| been seen.  Each word must be looked up and its index pushed on the stack
	0 -rot			| count a n
	repeat 
		ltrim
		32 split
		>r getix r>  | count a n ix true | count ix false
		over 0if
			nip
		else
			if
				-rot 2swap swap 1+ 2swap
				true
			else
				| count ix
				swap 1+
				false
			then
		then
	while
	| ... count 
	permute
	;
: also: ( <also> ) -1 throw ;
| This word must only occur *after* the 'related' words!  It's a good idea to
| place it at the bottom of the help file.
: related: 10 parse  related ;
create last_id 20 allot
: desc: ( <desc>^L ) 
    parsews drop c@ parse 
	enquote descbuf lplace 
	| write out the word
	langbuf @ if
		| put in the 'lang' table
		" insert into lang values (" buf lplace
		last_id count buf +lplace ,,
		39 buf c+lplace
		langbuf count buf +lplace 
		39 buf c+lplace
		,,
		descbuf lcount buf +lplace
		" )" buf +lplace
		langbuf off
		db buf lcount sql_exec
	else
		" insert into help values (NULL," buf lplace
		wordbuf count buf +lplace ,,
		stackbuf null? buf +lplace ,,
		ctxbuf notnull! buf +lplace ,,
		origbuf2 null? buf +lplace ,,
		osbuf null? buf +lplace ,,
		verbuf null? buf +lplace ,,
		descbuf lcount
		buf +lplace ,,
		currentlib count buf +lplace
		" )" buf +lplace
		db buf lcount sql_exec
		db " select last_insert_rowid() from help" sql_fetch$ 
			last_id place
	then
	;

variable #defs
: def: ( <name> <stack> <desc> )
	'. emit
	#defs ++
	getline wordbuf place
	verbose if wordbuf count type_ then
	stackbuf off
	ctxbuf off
	osbuf off
	descbuf off
	verbuf off
	; 

: init
	appdir pad place " help.db" pad +place pad count
	2dup delete sql_open dup to db 
	" create table help (ix integer primary key,word,stack,ctx,orig,os,ver,desc,lib)" sql_exec 
	db " create table also (ix integer, other integer)" sql_exec 
	db " create table libs (ix integer primary key, name)" sql_exec
	db " create table orig (ix integer primary key, name)" sql_exec
	db " create table lang (ix integer, lang, desc)" sql_exec
	db " insert into libs values (1, 'UNK')" sql_exec
	db " create index l1 on lang (ix,lang)" sql_exec
	" 1" currentlib place
	;
: readin  db sql_begin
	appdir 4 - pad place " src/help.txt" pad +place pad count 
	(include)
	db sql_commit
	;
: deinit  
	db sql_begin
	db " create index w1 on help(word)" sql_exec 
	db sql_commit
	db sql_close 
	0 to db ;

: dolib ( a n -- )
	slurp 2dup | a n a n
	" |||" search if
		| a n a1 a2
		4 /string eval
	then
	drop free
	;
: (dolibs) ( a n -- )
	origbuf off
	in~ ~os fullname 
	2dup " CVS/" search if 2drop 2drop ;then
	2dup " .svn/" search if 2drop 2drop ;then
	| a n
	2dup
	libdir nip cell- /string enquote origbuf place
	doorig
	
	verbose if origbuf count type cr  then
	db sql_begin
	" insert into libs values (NULL, " pad place
	origbuf count pad +place
	') pad c+place 
	db pad count sql_exec

	currentlib off
	" select ix from libs where name=" pad place
	origbuf count pad +place
	db pad count sql_fetch$ currentlib place
	dolib
	db sql_commit
	;
: dolibs
	| iterate over libraries and process each one ...
	['] (dolibs) ['] 2drop libdir in~ ~os rdir
	;

: nohelp
	cr
	db 
	" select name from orig where ix not in (select orig from help)"
	{
		0 sql_getcol$ type cr
		false
	} sql_fetch cr . ." libraries without help" cr
	;
init readin dolibs nohelp deinit 
cr #defs ? ." word definitions in database" cr bye

