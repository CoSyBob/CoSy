| The words in here are ones you might want to use, but are not included in the
| core of Reva:
: @s ( a b -- a@ b ) [ $1B8B1E8B , $1E89 2, ;    | mov ebx,[esi]; mov ebx,[ebx]; mov [esi],ebx
: @t ( a b c -- a@ b c ) [ $8B045E8B , $045E891B , ; | mov ebx,[esi+4]; mov ebx,[ebx]; mov [esi+4],ebx
: 2 [ $89fc768d , $40c03106 , $40 1, ;
: 0  ( -- 0 ) dup [ $c031 2, ; | xor eax, eax
: 1  ( -- 1 ) 0 1+ ;
: -1 ( -- -1 ) 0 1- ;
