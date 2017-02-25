| third edition of 'quoth'

variable #quotes

: qf quote ~

I have seen all the works that are done under the sun; and, behold, all is vanity and vexation of spirit.
-- Ecclesiastes 1:14

1 The words of the Preacher, the son of David, king in Jerusalem.
2 Vanity of vanities, saith the Preacher, vanity of vanities; all is vanity.
3 What profit hath a man of all his labour which he taketh under the sun?
4 One generation passeth away, and another generation cometh: but the earth abideth for ever.
5 The sun also ariseth, and the sun goeth down, and hasteth to his place where he arose.
6 The wind goeth toward the south, and turneth about unto the north; it whirleth about continually, and the wind returneth again according to his circuits.
7 All the rivers run into the sea; yet the sea is not full; unto the place from whence the rivers come, thither they return again.
8 All things are full of labour; man cannot utter it: the eye is not satisfied with seeing, nor the ear filled with hearing.
9 The thing that hath been, it is that which shall be; and that which is done is that which shall be done: and there is no new thing under the sun.
10 Is there any thing whereof it may be said, See, this is new? it hath been already of old time, which was before us.
11 There is no remembrance of former things; neither shall there be any remembrance of things that are to come with those that shall come after.
-- Ecclesiastes 1

For in much wisdom is much vexation; and he that increaseth knowledge increaseth sorrow.
-- Ecclesiastes 1:18

History teaches us that men and nations behave wisely once they have exhausted all 
other alternatives. -- Abba Eban

C++ is history repeated as tragedy. Java is history repeated as
farce. -- Scott McKay

The generation of random numbers is too important to be left to chance.

Curiosity *may* have killed Schrodinger's cat. 

Keep it short for pithy sake.

Remove the stone of shame. Attach the stone of triumph.

When you are educated, you'll believe only half of what you hear. When
you're intelligent, you know which half. -- Jerome Perryman

Atheism is a non-prophet organization.

The heart of the path is quite easy. There's no need to explain
anything at length. Let go of love and hate and let things be. That's
all that I do in my own practice. -- Ajahn Chah

Talent does what it can, genius what it must. I do what I get paid to
do.

Chopping the head off the chicken might seem like a good idea at the
time until you realise its the arsehole that becomes the new leader.

Fashion is something barbarous, for it produces innovation without
reason and imitation without benefit.  --Santayana

Success is something I will dress for when I get there, and not until.

C combines the power of assembler language with the convenience of
assembler language.

When your hammer is C++ everything starts to look like a thumb.

Underneath every Cynic is a disappointed Idealist.  --George Carlin

No trees were killed in sending this message.  However, a large number
of electrons were seriously inconvenienced.

If you have any trouble sounding condescending, find a Unix user to
show you how it's done.  --Scott Adams, Dilbert newsletter 3.0, 1994
~ ;

: countquotes ( -- )
	#quotes off qf
	repeat
		#quotes ++
		1 /string 12 /char 
		dup
	while 2drop ;

: speak ( n -- )
	qf rot
	0 ?do 1 /string 12 /char loop
	1 /string
	12 split 
	if 2swap 2drop then
	type cr 
	;

needs random/gm
: choose time&date 3drop ms seed4 rand abs #quotes @ mod ; | fancier randomness

: main countquotes choose speak bye ;
with~ ~sys
' main is appstart

| Change to '0' to generate an exe
1 [IF] main [ELSE]
" quoth" makeexename (save) bye
[THEN]
