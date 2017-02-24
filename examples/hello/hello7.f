| hello using string words:


| Make a buffer to hold the output string
create hellobuf 100 allot

| put "Hello, " in the buffer:
: hello " Hello, " hellobuf place ;

| append " world!" to the buffer:
: world " world!" hellobuf +place ;

| output the string:
: say hellobuf count type cr ;

| form the string:
hello world
| output it:
say
| goodbye!
bye
