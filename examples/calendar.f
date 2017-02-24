| vim: ic :

needs date/calendar
with~ ~date
: test gregorian>fixed fixed>gregorian .s cr reset ;
." today is: " .today cr
today cal
." tests:" cr
." (1 2 2003): " 1 2 2003 test 
." (12 31 2005): " 12 31 2005 test
." (4 15 1876): " 4 15 1876 test

needs date/hebrew
: .mm	2 pick . over . dup . ;
: testh ( mm dd yyyy ) 
	fixed>hebrew .s cr reset ;
: testgh 
	.mm ." : "
	gregorian>fixed fixed>hebrew hebrew>fixed fixed>gregorian 
	.mm
	cr reset ;
." hebrew calendar tests:" cr
." 5 10 3174: " -214194 testh
." 7 3 3831: " 25468 testh
." 8 12 5799: " 744312 testh
5 10 2004 testgh
1 1 2000 testgh
4 10 1943 testgh
12 31 2005 testgh
1 1 2006 testgh
." 30 Kislev 5766 - " 12 31 2005 gregorian>fixed fixed>hebrew .hebrew cr
." Today's hebrew date: " .hebrewtoday cr

bye
