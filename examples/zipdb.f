| zipdb
needs util/eachline
needs db/sqlite

with~ ~sys 
with~ ~db 

2variable file
value db
variable lines
2variable zip
2variable city
2variable state
2variable area
create infile 256 allot
create outfile 256 allot
" zip.db"  outfile place

: needfile
	quote "
	This program reads a 'CSV' formatted database file of zipcodes, for
	processing into a SQLite datbase.  You need to have provided a valid
	filename in order for it to work.
	" type
	bye
	;

: ok?
	case argc
		1 of needfile endof
		2 of argc argv infile place endof
		argc argv outfile place argc 1- 1- argv infile place
	endcase
	." INFILE: " infile count type cr
	." OUTFILE: " outfile count type cr
	infile count slurp over 0if 
		." Invalid file: " infile count type cr bye 
	then 
	file 2!
	;

: start
	outfile count sql_open to db
	db " create table zipcodes (zipcode integer primary key, city, statecode, areacode)" 
		sql_exec
	db " begin transaction" sql_exec
	." processing " infile count type ."  to " 
		outfile count type ." ..." cr
	;

: sp, ', split drop ;
: oneline lines @ 0if 
		2drop 
	else
		sp, zip 2! 
		sp, 2drop    |   ZipType
		sp, city 2!
		sp, drop c@ 'D =if		| city type
			| split the rest
			sp, 2drop | state name
			sp, state 2! | state abbrev
			sp, area 2! 2drop
			| insert the entry by making an entry
			" insert into zipcodes values ('" scratch place
				zip 2@ scratch +place
				" ','" scratch +place
				city 2@ scratch +place
				" ','" scratch +place
				state 2@ scratch +place
				" ','" scratch +place
				area 2@ scratch +place
				" ')" scratch +place

			db scratch count  sql_exec

		else
			| ignore the entry
			2drop
		then
	then
	lines ++  ;

: main
	ok? start
	file 2@ ['] oneline eachline
	." processed " lines ? ." lines" cr
	db " commit" sql_exec
	db sql_close
	file @ free ;

' main is appstart
" zdb" makeexename (save) bye
