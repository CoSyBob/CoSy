reva=`pwd`/bin/reva

if [ -x $reva ] ; 
then
	`pwd`/bin/reva bin/install.f
else
	echo "$reva does not exist, you need to be in the Reva directory"
fi
