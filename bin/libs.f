| Tell what versions of external libraries are being used:


needs db/sqlite
~db
." SQLite: " ~sqlite.sqlite3_libversion zcount type cr

needs string/regex
." PCRE: "
~priv.pcre_version zcount type cr


needs string/iconv
." libiconv: "
iconv_ver 256 /mod (.) type '. emit 256 /mod swap (.) type '. emit . cr

needs string/xmlparse
." libexpat: "
with~ ~xml
~expat.XML_ExpatVersion zcount type cr

bye
