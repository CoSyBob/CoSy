needs string/trim
: xml parsews 2dup ." <" type ." >"
      10 parse trim type
	  ." </" type ." >" cr ;

xml title My excellent title
xml author Ron
xml date 10 Aug 2005
bye
