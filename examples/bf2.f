| vim: ft=reva
|
| A simple brainfuck interpreter for Reva FORTH.
| Author: Danny Reinhold
|         (modified slightly by Ron Aaron)
| Reva's license terms also apply to this file.
| See: http://en.wikipedia.org/wiki/Brainfuck

30000 constant memory-size
create memory memory-size allot 
variable memory-pointer
variable instruction-pointer

| This is an array of function pointers which gets filled in later:
create commands 256 cells dup allot commands swap 0 fill

: prev-command ( -- c )
  instruction-pointer --
	| fall-through to get-instruction
: get-instruction instruction-pointer @ c@ ;
: next-command ( -- c )
  get-instruction
  instruction-pointer ++
;


: bf ( a n -- ) memory memory-size 0 fill memory memory-pointer !  
	drop  instruction-pointer ! 
	| fall-through to the bf interpreter:
: brainfuck next-command 0; commands swap cells + @ ?dup if execute then brainfuck ;

: skip-block ( level -- )
  0;

  next-command
  dup
  '[ =if drop 1+ skip-block ;then
  '] =if      1- skip-block ;then
  skip-block
;

: find-block-start ( level -- )
  0;

  prev-command
  dup
  '] =if drop 1+ find-block-start ;then
  '[ =if      1- find-block-start ;then
  find-block-start
;

| These are the actions:
: b> memory-pointer ++ ;
: b< memory-pointer -- ;
: b+ memory-pointer @ dup c@ 1+ swap c! ;
: b- memory-pointer @ dup c@ 1- swap c! ;
: b. memory-pointer @ c@ emit ;
: b, ~sys.>in @ c@  memory-pointer @ c! ;
: b[ memory-pointer @ c@ 0if 1 skip-block then ;
: b] memory-pointer @ c@ if prev-command drop 1 find-block-start then ;

| And this fills in the commands array with the specific actions to execute:
' b< commands '< cells + !
' b> commands '> cells + !
' b+ commands '+ cells + !
' b- commands '- cells + !
' b. commands '. cells + !
' b, commands ', cells + !
' b[ commands '[ cells + !
' b] commands '] cells + !

| example:
|
| This is Wikipedia's HelloWorld implementation...
context: ~bf
to~ ~bf bf
~bf
: hello quote ~
	++++++++++[>+++++++>++++++++++>+++>+<<<<-]
	>++.>+.+++++++..+++.>++.<<+++++++++++++++.
	>.+++.------.--------.>+.>.
~ bf ;
: squares quote ~
	++++[>+++++<-]>[<+++++>-]+<+[
	>[>+>+<<-]++>>[<<+>>-]>>>[-]++>[-]+
	>>>+[[-]++++++>>>]<<<[[<++++++++<++>>-]+<.<[>----<-]<]
	<<[>>>>>[>>>[-]+++++++++<[>-<-]+++++++++>[-[<->-]+[<<<]]<[>+<-]>]<<-]<<-
	]
	[Outputs square numbers from 0 to 10000.
	Daniel B Cristofani (cristofdathevanetdotcom)
	http://www.hevanet.com/cristofd/brainfuck/]
~ bf ;
: beer quote ~
	################################################
	#                                              #
	# 99 bottles of beer in 976 bytes of Brainfuck #
	# Composed by Aki Rossi                        #
	# aki dot rossi at iki dot fi                  #
	#                                              #
	################################################

	#
	# Set beer counter to 99
	#
	>>>>>>>>>
	>++++++++++[-<++++++++++>]<-
	<<<<<<<<<

	#
	# Create output registers
	#
	++++++++++[->++++>++++>++++>++++<<<<]	add 0x28 to all from (1) to (4)
	++++++++[->>>++++++++>++++++++<<<<]	add 0x40 to all from (3) and (4)
	++++[->>>>++++<<<<]			add 0x10 to (4)
	++++++++++				set (0) to LF
	>--------				set (1) to SP
	>++++					set (2) to comma

	>>>>>>>			go to beer counter (9)
	[
		# Verse init
		<<<<
		+++	state 1 in (5)
		>+	state 2 in (6)
		>++	state 3 in (7)
		<<	go to (5)
		[
			#####################
			# N bottles of beer #
			#####################
			>>>>		go to (9)
			[
				# Print the number in (9)
				# (conversion routine uncommented to save space)
				[->+>+<<]>>[-<<+>>]<[>++++++++++[->>+>+<<<]
				<[>>>[-<<<-[>]>>>>[<[>]>[---------->>]<++++
				++[-<++++++++>]<<[<->[->-<]]>->>>[>]+[<]<<[
				->>>[>]<+[<]<<]<>>]<<]<+>>[->+<<+>]>[-<+>]<
				<<<<]>>[-<<+>>]<<]>[-]>>>>>>[>]<[.[-]<]
				<<<<<<
				# and remain in (10) which is empty
			]>+<<	inc (11) and go to (9)
			[>]>>	if (9) empty go to (11) else (12)
			[
				<<<<<<<		go to (3)
				++++++.+.	no
				-------		reset (3)
				>>>>>>>		go to (11)
				>>		go to (12)
			]
			<[-]<[-]<		empty (11) and go to (9)
			<<<<<<<<.	SP
			>>------.	b
			+++++++++++++.	o
			>----..		tt
			<---.		l
			-------.	e
			>>>>>>->>>+<<<	dec (9) inc (11)
			[>]>>
			[	now in (12)
				<<<<<<<<	go to (4)
				-.+		s
				>>>>>>>		go to (11)
			]
			>-<<<+<<<<<
			<<<.		SP
			>>>-----.	o
			<+.		f
			<<.		SP
			>>----.		b
			+++..		ee
			>+++.		r
			<+++>++++++	reset registers

			>>		go to (6)

			###############
			# on the wall #
			###############
			[
				<<<<<.		SP
				>>+++++++.-.	on
				<<.		SP
				>>>----.	t
				<------.---.	he
				<<.		SP
				>>>+++.		w
				<----.		a
				+++++++++++..	ll
				---->+>>	reset and go to (6)
				-		dec (6)
			]

			#
			# comma LF
			#
			<<<<.
			<<.
			
			####################################
			# take one down and pass it around #
			####################################
			>>>>>>>		go to (7)
			-		dec (7)
			[>]>>		if not blank then skip loop
			[
				-		dec (9)
				<<<<<		go to (4)
				----.		t
				<-------.	a
				>---------.	k
				<++++.		e
				<<.		SP
				>>>++++.-.<.	one
				<<.		SP
				>>-.>+.		do
				++++++++.	w
				---------.	n
				<<<.		SP
				>>---.>.<+++.	and
				<<.		SP
				>>>++.<---.	pa
				>+++..		ss
				<<<.		SP
				>>++++++++.>+.	it
				<<<.		SP
				>>--------.	a
				>--.---.	ro
				++++++.		u
				-------.	n
				<+++.		d
				++++>++++++++++	reset registers
				<<.		comma
				<<.		LF
				>>-----------	set (2) to excl mark
				>>>>+		inc (6)
				>>>>		go to (10)
			]
			<<<
			<<		go to (5)
			-		dec (5)
		]
		>>+		inc (7)
		<<<<<<<.	LF
		>>+++++++++++	reset comma
		>>>>>>>		go to beer counter (9)
	]

~ bf ;
exit~ 

: main ~bf 
." Welcome to BrainF*ck for Reva.  Here are the example words: " cr words cr  ;
main
