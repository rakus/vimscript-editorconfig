"
" FILE: test_runner.vim
"
" ABSTRACT: Functions to run the editorconfig tests.
"

if !exists("g:TEST_COMPARE")
  let g:TEST_COMPARE = ""
endif

function! s:run_test(name, spec)
  let g:ecTestResult = ""
  let g:ecTestResultDict = {}
  let g:editor_config_info = []
  call editorconfig#ClearCache()

  if has_key(a:spec, "ec_file")
    let g:editor_config_file = a:spec.ec_file
  endif

  try
    let fn = a:spec.file
    try
      execute "silent edit " . fn
    catch /.*/
      call add(v:errors, v:exception)
      throw "Internal: " . v:exception
    endtry

    for [opt, value] in items(a:spec.expect)
      try
        let actual = eval(opt)
      catch /.*/
        let actual = 'exception in eval (' . v:exception . ')'
      endtry
      if g:TEST_COMPARE == 'regex'
        call assert_match(value, actual, a:name . ': ' . opt . ' wrong')
      else
        call assert_equal(value, actual, a:name . ': ' . opt . ' wrong')
      endif
    endfor
  finally
    call extend(g:editor_config_info, split(execute('EditorConfigStatus'), "\n"))
    bwipeout!
  endtry
endfunction


function! RunTestSet(name, tests)

  let all_errors = []

  let tst_count = 0
  let tst_fail = 0

  for [name, spec] in items(a:tests)
    let tst_count += 1
    let v:errors = []
    try
      call s:run_test(name, spec)
    catch /Internal: .*/
      " Ignored - already handled
    catch /.*/
      call add(v:errors, v:exception)
    endtry
    if !empty(v:errors)
      let tst_fail += 1
      let msgs = copy(v:errors)
      call extend(msgs, g:editor_config_info)
      call add(all_errors, [ name, msgs])
    endif
  endfor

  let testResult = []
  if !empty(all_errors)
    for ed in all_errors
      call add(testResult, "Test: " . ed[0])
      for msg in ed[1]
        call add(testResult, "  - " . msg)
      endfor
    endfor
  endif

  call add(testResult, a:name . ": Tests: " . tst_count . " Failed: " . tst_fail)

  call writefile(testResult, $TEST_RESULT_FILE)

  return tst_fail
endfunction

