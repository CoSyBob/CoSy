| --------------------------------------------------------------------
| test code:
| --------------------------------------------------------------------
needs db/sqlite
~db
context: ~test
~test
variable counter
value db

." Opening/creating the database..." cr
" test.db" 2dup delete sql_open to db 

." Populating the database..." cr
db sql_begin
db " create table a ( b char, c char )" sql_exec 
db " insert into a values ('one', 'first number')"  sql_exec 
db " insert into a values ('two', 'second number')" sql_exec
db " insert into a values ('three', 'after two')"  sql_exec
db " insert into a values ('four', 'two times two')"  sql_exec
db sql_commit

: newcb2 0 sql_getcol# '( emit . ." rows) " false ;

: newcb  ( n -- flag )
	dup .  ." columns: "
		0 do
			i sql_getcol$ type_
			db " select count() from a" ['] newcb2 sql_fetch drop
		loop
		cr
	false | means continue!
	;

db " select b, c from a" ' newcb sql_fetch
." processed " . ."  rows" cr


." sql_fetch$: "
db " select b, c from a" sql_fetch$ type cr


 db sql_close
 cr ." Done " cr
 exit~
 exit~
 bye
