
if !exists("g:SkipTestOnWindows")
  let g:SkipTestOnWindows = []
endif

function New_ec_test(name, ec_file, file, regex)
  if has_key(g:test_desc, a:name)
      call add(v:errors, 'Duplicate test ID: ' . a:name)
  endif
  if has("win32") && !has("win32unix") && index(g:SkipTestOnWindows, a:name) >= 0
    return
  endif
  let fn = s:escapeFile(a:file)
  let g:test_desc[a:name] = { 'file': fn, 'ec_file': a:ec_file, 'expect': { 'g:ecTestResult': a:regex }}
endfunction

function New_ec_test_multiline(name, ec_file, file, regex)
  if has_key(g:test_desc, a:name)
      call add(v:errors, 'Duplicate test ID: ' . a:name)
  endif
  if has("win32") && !has("win32unix") && index(g:SkipTestOnWindows, a:name) >= 0
    return
  endif
  let fn = s:escapeFile(a:file)
  let myre = substitute(a:regex, '+', '\\+', 'g')
  let g:test_desc[a:name] = { 'file': fn, 'ec_file': a:ec_file, 'expect': { 'g:ecTestResult': myre }}
endfunction

function s:escapeFile(fname)
  if !has("win32") && !has("win32unix")
    return escape(a:fname, ' {')
  else
    return escape(a:fname, ' ')
  endif
endfunction
