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

function s:appendToVar(varname, key, value)
  execute 'let ' . a:varname . '.="' . a:key . "=". a:value . '\n"'
endfunction

" Global variable g:ecTestResult defined in test_runner.vim
let g:editor_config_config = {
      \ 'key':                      funcref("s:appendToVar", [ "g:ecTestResult", 'key' ]),
      \ 'key1':                     funcref("s:appendToVar", [ "g:ecTestResult", 'key1' ]),
      \ 'key2':                     funcref("s:appendToVar", [ "g:ecTestResult", 'key2' ]),
      \ 'key4':                     funcref("s:appendToVar", [ "g:ecTestResult", 'key4' ]),
      \ 'child':                    funcref("s:appendToVar", [ "g:ecTestResult", 'child' ]),
      \ 'name':                     funcref("s:appendToVar", [ "g:ecTestResult", 'name' ]),
      \ 'charset':                  funcref("s:appendToVar", [ "g:ecTestResult", 'charset' ]),
      \ 'tab_width':                funcref("s:appendToVar", [ "g:ecTestResult", 'tab_width' ]),
      \ 'indent_size':              funcref("s:appendToVar", [ "g:ecTestResult", 'indent_size' ]),
      \ 'insert_final_newline':     funcref("s:appendToVar", [ "g:ecTestResult", 'insert_final_newline' ]),
      \ 'trim_trailing_whitespace': funcref("s:appendToVar", [ "g:ecTestResult", 'trim_trailing_whitespace' ]),
      \ 'indent_style':             funcref("s:appendToVar", [ "g:ecTestResult", 'indent_style' ]),
      \ 'end_of_line':              funcref("s:appendToVar", [ "g:ecTestResult", 'end_of_line' ]),
      \ }

let g:editor_config_debug = 3
runtime plugin/editorconfig.vim

execute "source " . escape(TEST_DIR, ' \')  . "/test_runner.vim"
execute "source " . escape(TEST_DIR, ' \')  . "/cmake_test_def.vim"

let g:test_desc = {}

" Test for EditorConfig file in parent directory
call New_ec_test("parent_directory", "parent_directory.in", "parent_directory/test.a", '^key=value[ \t\n\r]*$')

" Test for EditorConfig file in parent directory and current directory
call New_ec_test_multiline("parent_and_current_dir_ML", "parent_directory.in", "parent_directory/test.b", 'key1=value1[ \t]*[\n\r]+key2=value2[ \t\n\r]*')

"" Test for file in parent directory and overloaded by file in current directory
call New_ec_test("parent_dir_overload", "parent_directory.in", "parent_directory/test.c", '^key=valueB[ \t\n\r]*$')
"
"" Test for file in parent directory and overloaded by file in current directory and repeated in current directory
call New_ec_test("parent_dir_overload_repeat", "parent_directory.in", "parent_directory/test.d", '^key=value_c[ \t\n\r]*$')
"
"" Test for file in parent directory and overloaded by file in current directory and repeated in current directory, with different patterns
call New_ec_test("parent_dir_overload_repeat2", "parent_directory.in", "parent_directory/test.e", '^key=value_g[ \t\n\r]*$')
"
" Test that search stops at root EditorConfig file
call New_ec_test("root_file", "root_file.in", "root_file/test.a", '^[ \t\n\r]*$')
"
" Test that search stops at root EditorConfig file
call New_ec_test("root_file_mixed_case", "root_file.in", "root_mixed/test.a", '^child=true[ \t\n\r]*$')
"
"" Test that search stops at root EditorConfig file
call New_ec_test("root_pattern", "root_file.in", "root", '^name=root[ \t\n\r]*$')
"
"" Tests path separator match
call New_ec_test("path_separator", "path_separator.in", "path/separator", '^key1=value1[ \t\n\r]*$')

" Windows style path separator in the command line should work on Windows, but
" should not work on other systems (including Cygwin)
if has("win32")
  let path_separator_backslash_in_cmd_line_regex = '^key1=value1[ \t\n\r]*$'
else
  let path_separator_backslash_in_cmd_line_regex = '^[ \t\n\r]*$'
endif
call New_ec_test("path_separator_backslash_in_cmd_line", "path_separator.in", s:TEST_FILE_DIR . "path\\separator", path_separator_backslash_in_cmd_line_regex)

"" Tests path separator match below top of path
call New_ec_test("nested_path_separator", "path_separator.in", "nested/path/separator", '^[ \t\n\r]*$')
"
"" Tests path separator match top of path only
call New_ec_test("top_level_path_separator", "path_separator.in", "top/of/path", '^key2=value2[ \t\n\r]*$')
"
"" Tests path separator match top of path only
call New_ec_test("top_level_path_separator_neg", "path_separator.in", "not/top/of/path", '^[ \t\n\r]*$')
"
"" Test Windows-style path separator (backslash) does not work
call New_ec_test("windows_separator", "path_separator.in", "windows/separator", '^[ \t\n\r]*$')
"
"" Test again that Windows-style path separator (backslash) does not work
call New_ec_test("windows_separator2", "path_separator.in", "windows/separator2", '^[ \t\n\r]*$')
"
"" Globs with backslash in it but should be considered as file name on Non-Windows system
if !has("win32") && !has("win32unix")
  call New_ec_test("backslash_not_on_windows", "path_separator.in", "windows\\\\separator2", '^key4=value4[ \t\n\r]*$')
endif
"
call New_ec_test("path_with_special_chars", "path_with_special_chars.in", "path_with_special_[chars/test.a", '^key=value[ \t\n\r]*$')
""# " <-- resync the syntax highlighter
"
"" Test the unset value with various common properties
"call New_ec_test("unset_charset", "unset.in", "unset/charset.txt", '^charset=unset[ \t\n\r]*$')
"call New_ec_test("unset_end_of_line", "unset.in", "unset/end_of_line.txt", '^end_of_line=unset[ \t\n\r]*$')
"call New_ec_test_multiline("unset_indent_size_ML", "unset.in", "unset/indent_size.txt", 'indent_size=unset[ \t\n\r]*tab_width=unset[ \t\n\r]*')
"call New_ec_test("unset_indent_style", "unset.in", "unset/indent_style.txt", '^indent_style=unset[ \t\n\r]*$')
"call New_ec_test("unset_insert_final_newline", "unset.in", "unset/insert_final_newline.txt", '^insert_final_newline=unset[ \t\n\r]*$')
"call New_ec_test("unset_tab_width", "unset.in", "unset/tab_width.txt", '^tab_width=unset[ \t\n\r]*$')
"call New_ec_test("unset_trim_trailing_whitespace", "unset.in", "unset/trim_trailing_whitespace.txt", '^trim_trailing_whitespace=unset[ \t\n\r]*$')

call New_ec_test("unset_charset", "unset.in", "unset/charset.txt", '^$')
call New_ec_test("unset_end_of_line", "unset.in", "unset/end_of_line.txt", '^$')
call New_ec_test_multiline("unset_indent_size_ML", "unset.in", "unset/indent_size.txt", '^$')
call New_ec_test("unset_indent_style", "unset.in", "unset/indent_style.txt", '^$')
call New_ec_test("unset_insert_final_newline", "unset.in", "unset/insert_final_newline.txt", '^$')
call New_ec_test("unset_tab_width", "unset.in", "unset/tab_width.txt", '^$')
call New_ec_test("unset_trim_trailing_whitespace", "unset.in", "unset/trim_trailing_whitespace.txt", '^$')

execute "cd " . s:TEST_FILE_DIR
let g:TEST_COMPARE = 'regex'
if 0 != RunTestSet("editorconfig-core-filetree", g:test_desc)
  cq!
else
  quit!
endif

