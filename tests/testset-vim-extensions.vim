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

function s:addTest(name, desc) abort
  if has_key(s:test_desc, a:name)
      call add(v:errors, 'Duplicate test ID: ' . a:name)
  endif
  let s:test_desc[a:name] = a:desc
endfunction

" test vim extensions "spell_lang" & "spell_check"
call s:addTest('de_de.txt', { 'file': 'de_de.txt', 'expect': { '&spelllang': 'de_de', '&spell': 1 }})

" test blacklist by filename
call s:addTest('ignore_by_name.txt', { 'file': 'ignore_by_name.txt', 'expect': { '&tabstop != 11': 1 }})
" test blacklist by filename
call s:addTest('ignore_by_wildcard_name', { 'file': 'test.xyz', 'expect': { '&tabstop != 12': 1 }})
" test blacklist by filetyp
call s:addTest('ignore_by_filetype.c', { 'file': 'ignore_by_filetype.c', 'expect': { '&tabstop != 13': 1 }})
" test blacklist by filetyp glob expression
call s:addTest('ignore-ft-markdown', { 'file': 'ignored.md', 'expect': { '&tabstop != 14': 1 }})

" test file with leading dot is detected
call s:addTest('file-leading-dot', { 'file': '.vimrc', 'expect': { '&tabstop': 15 }})

" test backslashes in property value setting value `set` command
call s:addTest('escape_test', { 'file': 'escape_test.txt', 'expect': { '&directory': 'f:\not-there\also-not-there,.' }})

" test backslashes in property value setting value via funcref
call s:addTest('escape_test2', { 'file': 'escape_test2.txt', 'expect': { '&directory': 'f:\not-there\also-not-there,.' }})

" test var assignment single quotes
call s:addTest('buffer_local_var_single', { 'file': 'buffer_local_var.txt', 'expect': { 'b:buflocal': 'test\case' }})

" test var assignment double quotes
call s:addTest('buffer_local_var_double', { 'file': 'buffer_local_var2.txt', 'expect': { 'b:buflocal': 'case\test' }})

" test multibyte in glob choice
call s:addTest('multibyte-glob-choice', { 'file': 'multibyte-choice.中', 'expect': { 'b:buflocal': 'multibyte-choice' }})

" test multibyte in glob choice
call s:addTest('multibyte-glob-collection', { 'file': 'multibyte-collection.中', 'expect': { 'b:buflocal': 'multibyte-collection' }})

" test dot is correctly escaped in glob2re
call s:addTest('dot-escaped', { 'file': 'dot_c', 'expect': { '&tabstop != 16': 1 }})

" test filename with line break
call s:addTest('name-linebreak', { 'file': "test\\\ncase.abc", 'expect': { '&tabstop': 17 }})

" test filename with line break
call s:addTest('name-linebreak2', { 'file': "test\\\ncase.abd", 'expect': { '&tabstop': 18 }})

" Windows doesn't allow '*' or '?' in file names
if !has('win32')
  " test filename with asterisk (*)
  call s:addTest('name-asterisk', { 'file': 'a\*.abc', 'expect': { '&tabstop': 19 }})

  " test filename with question mark
  call s:addTest('name-question', { 'file': 'a\?.abc', 'expect': { '&tabstop': 20 }})
endif

" test filename with right square bracket
call s:addTest('name-right-square', { 'file': 'a[.abc', 'expect': { '&tabstop': 21 }})

if has('win32') && !has('win32unix')
  " test filename with right curly bracket
  call s:addTest('name-right-curly-escaped', { 'file': 'a{.abc', 'expect': { '&tabstop': 22 }})

  " test filename with right curly bracket 2
  call s:addTest('name-right-curly', { 'file': 'b{.abc', 'expect': { '&tabstop': 23 }})
else
  " test filename with right curly bracket
  call s:addTest('name-right-curly-escaped', { 'file': 'a\{.abc', 'expect': { '&tabstop': 22 }})

  " test filename with right curly bracket 2
  call s:addTest('name-right-curly', { 'file': 'b\{.abc', 'expect': { '&tabstop': 23 }})
endif

call s:addTest('slash-after-escaped-bracket', { 'file': 'ab[c]/]d', 'expect': { '&tabstop': 24 }})

if has('win32') && !has('win32unix')
  call s:addTest('braces-back-to-back', { 'file': '}test{.txt', 'expect': { '&tabstop': 25 }})
else
  call s:addTest('braces-back-to-back', { 'file': '\}test\{.txt', 'expect': { '&tabstop': 25 }})
endif

"testing number-ranges
call s:addTest('number-range-simple-0' , { 'file': 'number_0.num', 'expect': { '&tabstop': 26 }})
call s:addTest('number-range-simple-1' , { 'file': 'number_1.num', 'expect': { '&tabstop': 26 }})
call s:addTest('number-range-simple-85', { 'file': 'number_85.num', 'expect': { '&tabstop': 26 }})

" Leading zeros not supported by editorconfig
" see https://github.com/editorconfig/editorconfig/issues/371
" call s:addTest('number-range-simple-00' , { 'file': 'number_00.num', 'expect': { '&tabstop': 26 }})
" call s:addTest('number-range-simple-01' , { 'file': 'number_01.num', 'expect': { '&tabstop': 26 }})
" call s:addTest('number-range-simple-085', { 'file': 'number_085.num', 'expect': { '&tabstop': 26 }})
"
" call s:addTest('number-range-simple-000' , { 'file': 'number_000.num', 'expect': { '&tabstop': 26 }})
" call s:addTest('number-range-simple-001' , { 'file': 'number_001.num', 'expect': { '&tabstop': 26 }})
" call s:addTest('number-range-simple-0085', { 'file': 'number_0085.num', 'expect': { '&tabstop': 26 }})
"
" call s:addTest('number-range-simple-x00' , { 'file': 'number_000000000000000000000.num', 'expect': { '&tabstop': 26 }})
" call s:addTest('number-range-simple-x01' , { 'file': 'number_000000000000000000001.num', 'expect': { '&tabstop': 26 }})
" call s:addTest('number-range-simple-x085', { 'file': 'number_000000000000000000085.num', 'expect': { '&tabstop': 26 }})

"testing negative number-ranges
call s:addTest('negative-number-range-simple-0' , { 'file': 'neg_number_-0.num', 'expect': { '&tabstop': 27 }})
call s:addTest('negative-number-range-simple-1' , { 'file': 'neg_number_-1.num', 'expect': { '&tabstop': 27 }})
call s:addTest('negative-number-range-simple-85', { 'file': 'neg_number_-85.num', 'expect': { '&tabstop': 27 }})

" Leading zeros not supported by editorconfig
" see https://github.com/editorconfig/editorconfig/issues/371
" call s:addTest('negative-number-range-simple-00' , { 'file': 'neg_number_-00.num', 'expect': { '&tabstop': 27 }})
" call s:addTest('negative-number-range-simple-01' , { 'file': 'neg_number_-01.num', 'expect': { '&tabstop': 27 }})
" call s:addTest('negative-number-range-simple-085', { 'file': 'neg_number_-085.num', 'expect': { '&tabstop': 27 }})
"
" call s:addTest('negative-number-range-simple-000' , { 'file': 'neg_number_-000.num', 'expect': { '&tabstop': 27 }})
" call s:addTest('negative-number-range-simple-001' , { 'file': 'neg_number_-001.num', 'expect': { '&tabstop': 27 }})
" call s:addTest('negative-number-range-simple-0085', { 'file': 'neg_number_-0085.num', 'expect': { '&tabstop': 27 }})
"
" call s:addTest('negative-number-range-simple-x00' , { 'file': 'neg_number_-000000000000000000000.num', 'expect': { '&tabstop': 27 }})
" call s:addTest('negative-number-range-simple-x01' , { 'file': 'neg_number_-000000000000000000001.num', 'expect': { '&tabstop': 27 }})
" call s:addTest('negative-number-range-simple-x085', { 'file': 'neg_number_-000000000000000000085.num', 'expect': { '&tabstop': 27 }})

"testing negative-positive number-ranges
call s:addTest('neg-pos-number-range-simple--85', { 'file': 'both_number_-85.num', 'expect': { '&tabstop': 27 }})
call s:addTest('neg-pos-number-range-simple--1' , { 'file': 'both_number_-1.num', 'expect': { '&tabstop': 27 }})
call s:addTest('neg-pos-number-range-simple--0' , { 'file': 'both_number_-0.num', 'expect': { '&tabstop': 27 }})
call s:addTest('neg-pos-number-range-simple-+0' , { 'file': 'both_number_+0.num', 'expect': { '&tabstop': 27 }})
call s:addTest('neg-pos-number-range-simple-+1' , { 'file': 'both_number_+1.num', 'expect': { '&tabstop': 27 }})
call s:addTest('neg-pos-number-range-simple-+85', { 'file': 'both_number_+85.num', 'expect': { '&tabstop': 27 }})
call s:addTest('neg-pos-number-range-simple-0' , { 'file': 'both_number_0.num', 'expect': { '&tabstop': 27 }})
call s:addTest('neg-pos-number-range-simple-1' , { 'file': 'both_number_1.num', 'expect': { '&tabstop': 27 }})
call s:addTest('neg-pos-number-range-simple-85', { 'file': 'both_number_85.num', 'expect': { '&tabstop': 27 }})

" Leading zeros not supported by editorconfig
" see https://github.com/editorconfig/editorconfig/issues/371
" call s:addTest('neg-pos-number-range-simple-0085', { 'file': 'both_number_-0085.num', 'expect': { '&tabstop': 27 }})
" call s:addTest('neg-pos-number-range-simple-001' , { 'file': 'both_number_-001.num', 'expect': { '&tabstop': 27 }})
" call s:addTest('neg-pos-number-range-simple-000' , { 'file': 'both_number_-000.num', 'expect': { '&tabstop': 27 }})
" call s:addTest('neg-pos-number-range-simple-000' , { 'file': 'both_number_+000.num', 'expect': { '&tabstop': 27 }})
" call s:addTest('neg-pos-number-range-simple-001' , { 'file': 'both_number_+001.num', 'expect': { '&tabstop': 27 }})
" call s:addTest('neg-pos-number-range-simple-0085', { 'file': 'both_number_+0085.num', 'expect': { '&tabstop': 27 }})
" call s:addTest('neg-pos-number-range-simple-000' , { 'file': 'both_number_000.num', 'expect': { '&tabstop': 27 }})
" call s:addTest('neg-pos-number-range-simple-001' , { 'file': 'both_number_001.num', 'expect': { '&tabstop': 27 }})
" call s:addTest('neg-pos-number-range-simple-0085', { 'file': 'both_number_0085.num', 'expect': { '&tabstop': 27 }})

"testing number-ranges not octl
call s:addTest('number-range-no-octal1', { 'file': 'oct_number_10.num', 'expect': { '&tabstop': 28 }})
call s:addTest('number-range-no-octal2', { 'file': 'oct_number_20.num', 'expect': { '&tabstop': 28 }})
call s:addTest('number-range-no-octal3', { 'file': 'oct_number_8.num', 'expect': { '&tabstop==28': 0 }})

execute "cd " . s:TEST_FILE_DIR
if 0 != RunTestSet("vim-extensions", s:test_desc)
  cq!
else
  quit!
endif
testset-vim-extensions.vim
