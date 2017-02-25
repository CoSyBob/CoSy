needs net/xmlrpc

: try2
	" currentTime.getCurrentTime" 
	" time.xmlrpc.com/RPC2" 
	xmlrpc[ 
	]xmlrpc parse-result ;

: try
	" gtkphpnet.access_stats"
	" php-gtk.eu/xmlrpc.php"
	xmlrpc[ ]xmlrpc parse-result ;

: foldoc
	" foldoc.about"
	" scripts.incutio.com/xmlrpc/foldoc/server.php"
	xmlrpc[ ]xmlrpc parse-result ;

: geocode
	" geocode"
	" rpc.geocoder.us/service/xmlrpc"
	xmlrpc[
		" 1005 Gravenstein Hwy, Sebastopol, CA 95472" strval
	]xmlrpc parse-result ;

