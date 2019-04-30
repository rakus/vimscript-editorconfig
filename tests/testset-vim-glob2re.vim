"
" FILE: testset-vim-glob2re.vim
"
" ABSTRACT: test Glob to RE translation
"


let s:tst_count = 0
let s:tst_fail = 0
let testResult = []

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

    call add(testResult, "testG2RE - " . a:glob)
    for err in v:errors
      call add(testResult, " - " . err)
    endfor
  endif
endfunction

function s:numRange2Fn(min, max)
  return map(range(a:min, a:max), {i,v -> '/' . v})
endfunc

call s:testG2Re('{2..17}', s:numRange2Fn(2, 17), [ '/-2', '/-1', '/0', '/1', '/18', '/117', "/017" ])
call s:testG2Re('{-21..1217}', s:numRange2Fn(-21, 1217), [ '/-22', '/1218', '/2216' ])
call s:testG2Re('{-21..-17}', s:numRange2Fn(-21, -17), [ '/-22', '/-16' ])

" check automatic correction of range
call s:testG2Re('{-17..-21}', s:numRange2Fn(-21, -17), [ '/-22', '/-16' ])

let errors = !empty(testResult)

call add(testResult, "vim-glob2re: Tests: " . s:tst_count . " Failed: " . s:tst_fail)

call writefile(testResult, $TEST_RESULT_FILE)

if errors
  cq!
else
  quit!
endif


