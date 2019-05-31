"
" FILE: testset-vim-glob2re.vim
"
" ABSTRACT: test Glob to RE translation
"


let s:tst_count = 0
let s:tst_fail = 0
let s:testResult = []
let b:editorconfig_msgs = []

let g:editorconfig_debug = 3

function s:testG2Re(glob, matchList, noMatchList)
  let s:tst_count += 1
  let v:errors = []
  let re = editorconfig_g2re#GlobToRegEx(a:glob)
  "echo re

  for name in a:matchList
    call assert_match(re, name, "Match-Test")
  endfor

  for name in a:noMatchList
    call assert_notmatch(re, name, "NO-Match-Test")
  endfor
  if !empty(v:errors)
    let s:tst_fail += 1

    call add(s:testResult, "testG2RE - " . a:glob)
    for err in v:errors
      call add(s:testResult, " - " . err)
    endfor
  endif
endfunction

function s:glob_test(glob, regex)
  let s:tst_count += 1
  let v:errors = []
  let b:editorconfig_msgs = []

  "if a:regex[0] != '/'
  if stridx(a:glob, '/') < 0
    let expect = '/\(.*/\)\?' . a:regex
  else
    let expect = '/' . a:regex
  endif

  let re = editorconfig_g2re#GlobToRegEx(a:glob)

  if re != expect
    let s:tst_fail += 1
    call add(s:testResult, " - " . a:glob . ' Expected: "' . expect . '" Got: "' . re . '"')
    call extend(s:testResult, b:editorconfig_msgs)
  endif
  if !empty(v:errors)
    let s:tst_fail += 1
    call add(s:testResult, "glob_test - " . a:glob)
    for err in v:errors
      call add(s:testResult, " - " . err)
    endfor
  endif
endfunction

function s:numRange2Fn(min, max)
  return map(range(a:min, a:max), {i,v -> '/' . v})
endfunc

if editorconfig_g2re#NumberMode() == "ZEROS"
  call s:testG2Re('{2..17}', s:numRange2Fn(2, 17), [ '/-2', '/-1', '/0', '/1', '/18', '/117' ])
else
  call s:testG2Re('{2..17}', s:numRange2Fn(2, 17), [ '/-2', '/-1', '/0', '/1', '/18', '/117', "/017" ])
endif

call s:testG2Re('{-21..1217}', s:numRange2Fn(-21, 1217), [ '/-22', '/1218', '/2216' ])
call s:testG2Re('{-21..-17}', s:numRange2Fn(-21, -17), [ '/-22', '/-16' ])

" check automatic correction of range
call s:testG2Re('{-17..-21}', s:numRange2Fn(-21, -17), [ '/-22', '/-16' ])

" basics
call s:glob_test('*.c', '[^/]*\.c$')
call s:glob_test('a b.c', 'a b\.c$')
call s:glob_test('test/**/b.c', 'test/\%(.*/\)\?b\.c$')
call s:glob_test('test/*/b.c', 'test/[^/]*/b\.c$')
call s:glob_test('**/b.c', '.*/b\.c$')
call s:glob_test('ab?.c', 'ab[^/]\.c$')

" escaped special chars
call s:glob_test('a\*.c', 'a\*\.c$')
call s:glob_test('a\?.c', 'a?\.c$')
call s:glob_test('a\{.c', 'a{\.c$')
call s:glob_test('a\[.c', 'a\[\.c$')

" brackets
call s:glob_test('[abc]', '[abc]$')
call s:glob_test('[a-z]', '[a-z]$')

" support ^ and ! as negation
call s:glob_test('[!abc]', '[^abc]$')
call s:glob_test('[^abc]', '[^abc]$')

call s:glob_test('[abc[]', '[abc[]$')
call s:glob_test('[abc\[]', '[abc[]$')
call s:glob_test('[abc\]]', '[abc\]]$')
call s:glob_test('[abc\[\]]', '[abc[\]]$')
call s:glob_test('[abc[\]]', '[abc[\]]$')

call s:glob_test('[test[abc]', '[test[abc]$')
call s:glob_test('[test\[abc]', '[test[abc]$')
call s:glob_test('[test\]abc]', '[test\]abc]$')
call s:glob_test('[test]abc]', '[test]abc\]$')
call s:glob_test('[test', '\[test$')
call s:glob_test(']test', '\]test$')

" choice
call s:glob_test('{}', '{}$')
call s:glob_test('{test}', '{test}$')
call s:glob_test('{test,case}', '\%(test\|case\)$')
call s:glob_test('{test,case,}', '\%(test\|case\|\)$')
call s:glob_test('{test,case,[!abc]}', '\%(test\|case\|[^abc]\)$')

" comma inside brackets is choice separator
call s:glob_test('{test[a,b]case,2}', '\%(test\[a\|b\]case\|2\)$')
call s:glob_test('{test[a\,b]case,2}', '\%(test[a,b]case\|2\)$')

" choice in choice
call s:glob_test('test.{a-{first,second},b-{third,fourth}}', 'test\.\%(a-\%(first\|second\)\|b-\%(third\|fourth\)\)$')

" incomplete outer braces
call s:glob_test('{test{test,case}', '{test\%(test\|case\)$')
call s:glob_test('test{test,case}}', 'test\%(test\|case\)}$')

" back to back braces
call s:glob_test('}test{', '}test{$')

" simple number ranges
if editorconfig_g2re#NumberMode() == "AS_IS"
  call s:glob_test('{0..9}', '\%(+\?\%([0-9]\)\)$')
  call s:glob_test('{1..5}', '\%(+\?\%([1-5]\)\)$')
  call s:glob_test('{+1..5}', '\%(+\?\%([1-5]\)\)$')
  call s:glob_test('{1..+5}', '\%(+\?\%([1-5]\)\)$')
  call s:glob_test('{+1..+5}', '\%(+\?\%([1-5]\)\)$')
  call s:glob_test('{5..1}', '\%(+\?\%([1-5]\)\)$')
  call s:glob_test('{0..5}', '\%(+\?\%([0-5]\)\)$')
  call s:glob_test('{0..15}', '\%(+\?\%([0-9]\|1[0-5]\)\)$')
  call s:glob_test('{9..15}', '\%(+\?\%(9\|1[0-5]\)\)$')
  call s:glob_test('{10..15}', '\%(+\?\%(1[0-5]\)\)$')
  call s:glob_test('{11..15}', '\%(+\?\%(1[1-5]\)\)$')
  call s:glob_test('{11..20}', '\%(+\?\%(1[1-9]\|20\)\)$')
  call s:glob_test('{11..23}', '\%(+\?\%(1[1-9]\|2[0-3]\)\)$')
  call s:glob_test('{11..32}', '\%(+\?\%(1[1-9]\|2[0-9]\|3[0-2]\)\)$')
  call s:glob_test('{11..39}', '\%(+\?\%(1[1-9]\|[2-3][0-9]\)\)$')
  call s:glob_test('{1..39}', '\%(+\?\%([1-9]\|[1-3][0-9]\)\)$')
  call s:glob_test('{0..39}', '\%(+\?\%([0-9]\|[1-3][0-9]\)\)$')
  call s:glob_test('{0..999}', '\%(+\?\%([0-9]\|[1-9][0-9]\|[1-9][0-9][0-9]\)\)$')
  call s:glob_test('{0..9999}', '\%(+\?\%([0-9]\|[1-9][0-9]\|[1-9][0-9][0-9]\|[1-9][0-9][0-9][0-9]\)\)$')
  call s:glob_test('{0..99999}', '\%(+\?\%([0-9]\|[1-9][0-9]\|[1-9][0-9][0-9]\|[1-9][0-9][0-9][0-9]\|[1-9][0-9][0-9][0-9][0-9]\)\)$')

  call s:glob_test('{-1..-5}', '\%(-\%([1-5]\)\)$')
  call s:glob_test('{-5..-1}', '\%(-\%([1-5]\)\)$')
  call s:glob_test('{0..-5}', '\%(-\%([0-5]\)\|+\?\%(0\)\)$')
  call s:glob_test('{-0..-5}', '\%(-\%([0-5]\)\|+\?\%(0\)\)$')
  call s:glob_test('{+0..-5}', '\%(-\%([0-5]\)\|+\?\%(0\)\)$')

  call s:glob_test('{-3..5}', '\%(-\%([0-3]\)\|+\?\%([0-5]\)\)$')

elseif editorconfig_g2re#NumberMode() == "ZEROS"
  call s:glob_test('{0..9}', '\%(+\?0*\%([0-9]\)\)$')
  call s:glob_test('{1..5}', '\%(+\?0*\%([1-5]\)\)$')
  call s:glob_test('{+1..5}', '\%(+\?0*\%([1-5]\)\)$')
  call s:glob_test('{1..+5}', '\%(+\?0*\%([1-5]\)\)$')
  call s:glob_test('{+1..+5}', '\%(+\?0*\%([1-5]\)\)$')
  call s:glob_test('{5..1}', '\%(+\?0*\%([1-5]\)\)$')
  call s:glob_test('{0..5}', '\%(+\?0*\%([0-5]\)\)$')
  call s:glob_test('{0..15}', '\%(+\?0*\%([0-9]\|1[0-5]\)\)$')
  call s:glob_test('{9..15}', '\%(+\?0*\%(9\|1[0-5]\)\)$')
  call s:glob_test('{10..15}', '\%(+\?0*\%(1[0-5]\)\)$')
  call s:glob_test('{11..15}', '\%(+\?0*\%(1[1-5]\)\)$')
  call s:glob_test('{11..20}', '\%(+\?0*\%(1[1-9]\|20\)\)$')
  call s:glob_test('{11..23}', '\%(+\?0*\%(1[1-9]\|2[0-3]\)\)$')
  call s:glob_test('{11..32}', '\%(+\?0*\%(1[1-9]\|2[0-9]\|3[0-2]\)\)$')
  call s:glob_test('{11..39}', '\%(+\?0*\%(1[1-9]\|[2-3][0-9]\)\)$')
  call s:glob_test('{1..39}', '\%(+\?0*\%([1-9]\|[1-3][0-9]\)\)$')
  call s:glob_test('{0..39}', '\%(+\?0*\%([0-9]\|[1-3][0-9]\)\)$')
  call s:glob_test('{0..999}', '\%(+\?0*\%([0-9]\|[1-9][0-9]\|[1-9][0-9][0-9]\)\)$')
  call s:glob_test('{0..9999}', '\%(+\?0*\%([0-9]\|[1-9][0-9]\|[1-9][0-9][0-9]\|[1-9][0-9][0-9][0-9]\)\)$')
  call s:glob_test('{0..99999}', '\%(+\?0*\%([0-9]\|[1-9][0-9]\|[1-9][0-9][0-9]\|[1-9][0-9][0-9][0-9]\|[1-9][0-9][0-9][0-9][0-9]\)\)$')

  call s:glob_test('{-1..-5}', '\%(-0*\%([1-5]\)\)$')
  call s:glob_test('{-5..-1}', '\%(-0*\%([1-5]\)\)$')
  call s:glob_test('{0..-5}', '\%(-0*\%([0-5]\)\|+\?0*\%(0\)\)$')
  call s:glob_test('{-0..-5}', '\%(-0*\%([0-5]\)\|+\?0*\%(0\)\)$')
  call s:glob_test('{+0..-5}', '\%(-0*\%([0-5]\)\|+\?0*\%(0\)\)$')

  call s:glob_test('{-3..5}', '\%(-0*\%([0-3]\)\|+\?0*\%([0-5]\)\)$')

elseif editorconfig_g2re#NumberMode() == "JUSTIFIED"
  call s:glob_test('{0..9}', '\%([0-9]\)$')
  call s:glob_test('{1..5}', '\%([1-5]\)$')
  call s:glob_test('{+1..5}', '\%([1-5]\)$')
  call s:glob_test('{1..+5}', '\%([1-5]\)$')
  call s:glob_test('{+1..+5}', '\%([1-5]\)$')
  call s:glob_test('{5..1}', '\%([1-5]\)$')
  call s:glob_test('{0..5}', '\%([0-5]\)$')
  call s:glob_test('{0..15}', '\%([0-9]\|1[0-5]\)$')
  call s:glob_test('{9..15}', '\%(9\|1[0-5]\)$')
  call s:glob_test('{10..15}', '\%(1[0-5]\)$')
  call s:glob_test('{11..15}', '\%(1[1-5]\)$')
  call s:glob_test('{11..20}', '\%(1[1-9]\|20\)$')
  call s:glob_test('{11..23}', '\%(1[1-9]\|2[0-3]\)$')
  call s:glob_test('{11..32}', '\%(1[1-9]\|2[0-9]\|3[0-2]\)$')
  call s:glob_test('{11..39}', '\%(1[1-9]\|[2-3][0-9]\)$')
  call s:glob_test('{1..39}', '\%([1-9]\|[1-3][0-9]\)$')
  call s:glob_test('{0..39}', '\%([0-9]\|[1-3][0-9]\)$')
  call s:glob_test('{0..999}', '\%([0-9]\|[1-9][0-9]\|[1-9][0-9][0-9]\)$')
  call s:glob_test('{0..9999}', '\%([0-9]\|[1-9][0-9]\|[1-9][0-9][0-9]\|[1-9][0-9][0-9][0-9]\)$')
  call s:glob_test('{0..99999}', '\%([0-9]\|[1-9][0-9]\|[1-9][0-9][0-9]\|[1-9][0-9][0-9][0-9]\|[1-9][0-9][0-9][0-9][0-9]\)$')

  call s:glob_test('{-1..-5}', '\%(-\%([1-5]\)\)$')
  call s:glob_test('{-5..-1}', '\%(-\%([1-5]\)\)$')
  call s:glob_test('{0..-5}', '\%(-\%([1-5]\)\|0\)$')
  call s:glob_test('{-0..-5}', '\%(-\%([1-5]\)\|0\)$')
  call s:glob_test('{+0..-5}', '\%(-\%([1-5]\)\|0\)$')

  call s:glob_test('{-3..5}', '\%(-\%([1-3]\)\|[0-5]\)$')

endif



" justified number ranges
if editorconfig_g2re#NumberMode() == "JUSTIFIED"
  call s:glob_test('{00..15}', '\%(0[0-9]\|1[0-5]\)$')
  call s:glob_test('{15..00}', '\%(0[0-9]\|1[0-5]\)$')
  call s:glob_test('{010..020}', '\%(01[0-9]\|020\)$')
  call s:glob_test('{01..39}', '\%(0[1-9]\|[1-3][0-9]\)$')
  call s:glob_test('{00..39}', '\%(0[0-9]\|[1-3][0-9]\)$')
  call s:glob_test('{00..999}', '\%([0-9][0-9][0-9]\)$')
  call s:glob_test('{0..0999}', '\%(0[0-9][0-9][0-9]\)$')
  call s:glob_test('{00..-999}', '\%(-\%(00[1-9]\|0[1-9][0-9]\|[1-9][0-9][0-9]\)\|0000\)$')
  call s:glob_test('{-00..9999}', '\%([0-9][0-9][0-9][0-9]\)$')
  call s:glob_test('{0..-09999}', '\%(-\%(0000[1-9]\|000[1-9][0-9]\|00[1-9][0-9][0-9]\|0[1-9][0-9][0-9][0-9]\)\|000000\)$')
  call s:glob_test('{-03..5}', '\%(-\%(0[1-3]\)\|00[0-5]\)$')
endif

let errors = !empty(s:testResult)

call add(s:testResult, 'vim-glob2re: Tests: ' . s:tst_count . ' Failed: ' . s:tst_fail)

call writefile(s:testResult, $TEST_RESULT_FILE)

if errors
  cq!
else
  quit!
endif


