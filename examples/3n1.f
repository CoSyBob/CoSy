| This example shows how to do input and some numeric munging.
|
| It implements the "3N+1" sequences:

with~ ~util

: about quote *
	This program computes and displays several 3N+1 sequences.  Starting values
	for the sequences are input by the user.  Terms in a sequence are printed in
	turn, until there are no more terms.  After a sequence has been displayed,
	the number of terms in that sequence is reported to the user.

	Type 'play' to start.
* type cr ;

: seeyou cr ." Thanks for playing!" cr bye ;

: getstart ( -- n )
	cr ." Enter the starting value (ESC or ENTER to quit): "
	scratch 20 accept ?dup 0if seeyou ;then
	scratch swap >single 0if
		cr ." The value '" type ." ', is not a valid number" getstart 
	then
	dup 0 <if
		drop cr ." Please input only positive integers, thank you" getstart
	then
	;

variable total
: doseq ( n -- )
	total ++
	dup .
	1- 0; 1+
	dup 1 and if
		| odd
		3 * 1+
	else
		2/
		| even
	then
	doseq
	;
: printseq ( n -- )
	total off
	dup cr ." The 3N+1 sequence starting with " . ." :" cr
	doseq
	cr ." Total in sequence: " total ? 
	;
about 
: play getstart printseq play ;
