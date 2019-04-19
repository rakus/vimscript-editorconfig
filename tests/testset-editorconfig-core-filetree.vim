"
" FILE: testset-editorconfig-core-filetree.vim
"
" ABSTRACT: Tests from editorconfig-core-test, section "filetree"
"
" https://github.com/editorconfig/editorconfig-core-test/tree/master/filetree
"
" This code is based on test code from the editorconfig-core-test project
" which is Copyright (c) 2011-2018 EditorConfig Team
" See https://github.com/editorconfig/editorconfig-core-test/blob/master/LICENSE.txt
"

let TEST_DIR=expand("<sfile>:h")
let PLUGIN_RTP = TEST_DIR . '/..'

let s:TEST_FILE_DIR=TEST_DIR . '/editorconfig-core-test/filetree/'

" Global variable g:ecTestResult defined in test_runner.vim
let g:editor_config_config = {
      \ 'key':                      { 'execute': "let g:ecTestResult .= 'key={v}\n'" },
      \ 'key1':                     { 'execute': "let g:ecTestResult .= 'key1={v}\n'" },
      \ 'key2':                     { 'execute': "let g:ecTestResult .= 'key2={v}\n'" },
      \ 'key4':                     { 'execute': "let g:ecTestResult .= 'key4={v}\n'" },
      \ 'child':                    { 'execute': "let g:ecTestResult .= 'child={v}\n'" },
      \ 'name':                     { 'execute': "let g:ecTestResult .= 'name={v}\n'" },
      \ 'charset':                  { 'execute': "let g:ecTestResult .= 'charset={v}\n'" },
      \ 'tab_width':                { 'execute': "let g:ecTestResult .= 'tab_width={v}\n'" },
      \ 'indent_size':              { 'execute': "let g:ecTestResult .= 'indent_size={v}\n'" },
      \ 'insert_final_newline':     { 'execute': "let g:ecTestResult .= 'insert_final_newline={v}\n'" },
      \ 'trim_trailing_whitespace': { 'execute': "let g:ecTestResult .= 'trim_trailing_whitespace={v}\n'" },
      \ 'indent_style':             { 'execute': "let g:ecTestResult .= 'indent_style={v}\n'" },
      \ 'end_of_line':              { 'execute': "let g:ecTestResult .= 'end_of_line={v}\n'" },
      \ }


let g:editor_config_debug = 3
runtime plugin/editorconfig.vim

execute "source " . escape(TEST_DIR, ' \')  . "/test_runner.vim"

let s:test_desc = {}

function s:new_ec_test(name, ec_file, file, regex)
  let s:test_desc[a:name] = { 'file': a:file, 'ec_file': a:ec_file, 'expect': { 'g:ecTestResult': a:regex }}
endfunction

function s:new_ec_test_multiline(name, ec_file, file, regex)
  let myre = substitute(a:regex, '+', '\\+', 'g')
  let s:test_desc[a:name] = { 'file': a:file, 'ec_file': a:ec_file, 'expect': { 'g:ecTestResult': myre }}
endfunction

" Test for EditorConfig file in parent directory
call s:new_ec_test("parent_directory", "parent_directory.in", "parent_directory/test.a", '^key=value[ \t\n\r]*$')

" Test for EditorConfig file in parent directory and current directory
call s:new_ec_test_multiline("parent_and_current_dir_ML", "parent_directory.in", "parent_directory/test.b", 'key1=value1[ \t]*[\n\r]+key2=value2[ \t\n\r]*')

"" Test for file in parent directory and overloaded by file in current directory
call s:new_ec_test("parent_dir_overload", "parent_directory.in", "parent_directory/test.c", '^key=valueB[ \t\n\r]*$')
"
"" Test for file in parent directory and overloaded by file in current directory and repeated in current directory
call s:new_ec_test("parent_dir_overload_repeat", "parent_directory.in", "parent_directory/test.d", '^key=value_c[ \t\n\r]*$')
"
"" Test for file in parent directory and overloaded by file in current directory and repeated in current directory, with different patterns
call s:new_ec_test("parent_dir_overload_repeat2", "parent_directory.in", "parent_directory/test.e", '^key=value_g[ \t\n\r]*$')
"
" Test that search stops at root EditorConfig file
call s:new_ec_test("root_file", "root_file.in", "root_file/test.a", '^[ \t\n\r]*$')
"
" Test that search stops at root EditorConfig file
call s:new_ec_test("root_file_mixed_case", "root_file.in", "root_mixed/test.a", '^child=true[ \t\n\r]*$')
"
"" Test that search stops at root EditorConfig file
call s:new_ec_test("root_pattern", "root_file.in", "root", '^name=root[ \t\n\r]*$')
"
"" Tests path separator match
call s:new_ec_test("path_separator", "path_separator.in", "path/separator", '^key1=value1[ \t\n\r]*$')

" Windows style path separator in the command line should work on Windows, but
" should not work on other systems (including Cygwin)
if has("win32")
  let path_separator_backslash_in_cmd_line_regex = '^key1=value1[ \t\n\r]*$'
else
  let path_separator_backslash_in_cmd_line_regex = '^[ \t\n\r]*$'
endif
call s:new_ec_test("path_separator_backslash_in_cmd_line", "path_separator.in", s:TEST_FILE_DIR . "path\\separator", path_separator_backslash_in_cmd_line_regex)

"" Tests path separator match below top of path
call s:new_ec_test("nested_path_separator", "path_separator.in", "nested/path/separator", '^[ \t\n\r]*$')
"
"" Tests path separator match top of path only
call s:new_ec_test("top_level_path_separator", "path_separator.in", "top/of/path", '^key2=value2[ \t\n\r]*$')
"
"" Tests path separator match top of path only
call s:new_ec_test("top_level_path_separator_neg", "path_separator.in", "not/top/of/path", '^[ \t\n\r]*$')
"
"" Test Windows-style path separator (backslash) does not work
call s:new_ec_test("windows_separator", "path_separator.in", "windows/separator", '^[ \t\n\r]*$')
"
"" Test again that Windows-style path separator (backslash) does not work
call s:new_ec_test("windows_separator2", "path_separator.in", "windows/separator2", '^[ \t\n\r]*$')
"
"" Globs with backslash in it but should be considered as file name on Non-Windows system
if !has("win32") && !has("win32unix")
  call s:new_ec_test("backslash_not_on_windows", "path_separator.in", "windows\\\\separator2", '^key4=value4[ \t\n\r]*$')
endif
"
call s:new_ec_test("path_with_special_chars", "path_with_special_chars.in", "path_with_special_[chars/test.a", '^key=value[ \t\n\r]*$')
""# " <-- resync the syntax highlighter
"
"" Test the unset value with various common properties
"call s:new_ec_test("unset_charset", "unset.in", "unset/charset.txt", '^charset=unset[ \t\n\r]*$')
"call s:new_ec_test("unset_end_of_line", "unset.in", "unset/end_of_line.txt", '^end_of_line=unset[ \t\n\r]*$')
"call s:new_ec_test_multiline("unset_indent_size_ML", "unset.in", "unset/indent_size.txt", 'indent_size=unset[ \t\n\r]*tab_width=unset[ \t\n\r]*')
"call s:new_ec_test("unset_indent_style", "unset.in", "unset/indent_style.txt", '^indent_style=unset[ \t\n\r]*$')
"call s:new_ec_test("unset_insert_final_newline", "unset.in", "unset/insert_final_newline.txt", '^insert_final_newline=unset[ \t\n\r]*$')
"call s:new_ec_test("unset_tab_width", "unset.in", "unset/tab_width.txt", '^tab_width=unset[ \t\n\r]*$')
"call s:new_ec_test("unset_trim_trailing_whitespace", "unset.in", "unset/trim_trailing_whitespace.txt", '^trim_trailing_whitespace=unset[ \t\n\r]*$')

call s:new_ec_test("unset_charset", "unset.in", "unset/charset.txt", '^$')
call s:new_ec_test("unset_end_of_line", "unset.in", "unset/end_of_line.txt", '^$')
call s:new_ec_test_multiline("unset_indent_size_ML", "unset.in", "unset/indent_size.txt", '^$')
call s:new_ec_test("unset_indent_style", "unset.in", "unset/indent_style.txt", '^$')
call s:new_ec_test("unset_insert_final_newline", "unset.in", "unset/insert_final_newline.txt", '^$')
call s:new_ec_test("unset_tab_width", "unset.in", "unset/tab_width.txt", '^$')
call s:new_ec_test("unset_trim_trailing_whitespace", "unset.in", "unset/trim_trailing_whitespace.txt", '^$')

execute "lcd " . s:TEST_FILE_DIR
let g:TEST_COMPARE = 'regex'
if 0 != RunTestSet("editorconfig-core-properties", s:test_desc)
  cq!
else
  quit!
endif

