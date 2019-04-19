"
" FILE: testset-vim-extensions.vim
"
" ABSTRACT: Test Vim specific editorconfig extensions
"

let TEST_DIR=expand("<sfile>:h")

let s:TEST_FILE_DIR=TEST_DIR . '/vim_extension_tests/'

let g:editor_config_debug = 3
runtime plugin/editorconfig.vim

function s:SetDirectoryOption(val)
  let &directory = a:val
endfunction

let g:editor_config_config = {
      \ 'string':    { 'execute': 'set directory={e}' },
      \ 'string2':   { 'execute': funcref("s:SetDirectoryOption") },
      \ 'buflocal':  { 'execute': "let b:buflocal='{v}'" },
      \ 'buflocal2': { 'execute': 'let b:buflocal="{e}"' },
      \ }
execute "source " . escape(TEST_DIR, ' \')  . "/test_runner.vim"

let g:editor_config_blacklist = {
      \ 'filetype': [ 'c', 'mark*'],
      \ 'filename': [ 'ignore_by_name.txt', '*.xyz' ]
      \ }


let s:test_desc = {}
" test vim extensions "spell_lang" & "spell_check"
let s:test_desc['de_de.txt'] = { 'file': 'de_de.txt', 'expect': { '&spelllang': 'de_de', '&spell': 1 }}

" test blacklist by filename
let s:test_desc['ignore_by_name.txt'] = { 'file': 'ignore_by_name.txt', 'expect': { '&tabstop != 11': 1 }}
" test blacklist by filename
let s:test_desc['ignore_by_wildcard_name'] = { 'file': 'test.xyz', 'expect': { '&tabstop != 12': 1 }}
" test blacklist by filetyp
let s:test_desc['ignore_by_filetype.c'] = { 'file': 'ignore_by_filetype.c', 'expect': { '&tabstop != 13': 1 }}
" test blacklist by filetyp glob expression
let s:test_desc['ignore-ft-markdown'] = { 'file': 'ignored.md', 'expect': { '&tabstop != 14': 1 }}

" test file with leading dot is detected
let s:test_desc['file-leading-dot'] = { 'file': '.vimrc', 'expect': { '&tabstop': 15 }}

" test backslashes in property value setting value `set` command
let s:test_desc['escape_test'] = { 'file': 'escape_test.txt', 'expect': { '&directory': 'f:\not-there\also-not-there,.' }}

" test backslashes in property value setting value via funcref
let s:test_desc['escape_test2'] = { 'file': 'escape_test2.txt', 'expect': { '&directory': 'f:\not-there\also-not-there,.' }}

" test var assignment single quotes
let s:test_desc['buffer_local_var_single'] = { 'file': 'buffer_local_var.txt', 'expect': { 'b:buflocal': 'test\case' }}

" test var assignment double quotes
let s:test_desc['buffer_local_var_double'] = { 'file': 'buffer_local_var2.txt', 'expect': { 'b:buflocal': 'case\test' }}


execute "cd " . s:TEST_FILE_DIR
if 0 != RunTestSet("vim-extensions", s:test_desc)
  cq!
else
  quit!
endif

