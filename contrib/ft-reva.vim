setlocal ic ts=4 sts=4 sw=4 
setlocal com=s1:/*,mb:*,ex:*/,:\|,:\\
setlocal fo=tcrqol
setlocal matchpairs+=\::;
setlocal iskeyword=!,@,33-35,%,$,38-64,A-Z,91-96,a-z,123-126,128-255
map <buffer> [[ ?^\s*:?<CR>
map <buffer> ]] /^\s*:/<CR>
