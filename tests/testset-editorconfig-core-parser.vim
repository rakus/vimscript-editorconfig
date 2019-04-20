"
" FILE: testset-editorconfig-core-parser.vim
"
" ABSTRACT: Tests from editorconfig-core-test, section "parser"
"
" https://github.com/editorconfig/editorconfig-core-test/tree/master/parser
"
" This code is based on test code from the editorconfig-core-test project
" which is Copyright (c) 2011-2018 EditorConfig Team
" See https://github.com/editorconfig/editorconfig-core-test/blob/master/LICENSE.txt
"

let TEST_DIR=expand("<sfile>:h")
let PLUGIN_RTP = TEST_DIR . '/..'

let s:TEST_FILE_DIR=TEST_DIR . '/editorconfig-core-test/parser/'

" Global variable g:ecTestResult defined in test_runner.vim
let g:editor_config_config = {
      \ 'key':     { 'execute': "let g:ecTestResult .= 'key={v}\n'" },
      \ 'key1':    { 'execute': "let g:ecTestResult .= 'key1={v}\n'" },
      \ 'key2':    { 'execute': "let g:ecTestResult .= 'key2={v}\n'" },
      \ 'key3':    { 'execute': "let g:ecTestResult .= 'key3={v}\n'" },
      \ 'name':    { 'execute': "let g:ecTestResult .= 'name={v}\n'" },
      \ 'option1': { 'execute': "let g:ecTestResult .= 'option1={v}\n'" },
      \ 'option2': { 'execute': "let g:ecTestResult .= 'option2={v}\n'" },
      \ '00000000000000000000000000000000000000000000000001': { 'execute': "let g:ecTestResult .= '00000000000000000000000000000000000000000000000001={v}\n'" },
      \ 'k255':    { 'execute': "let g:ecTestResult .= 'k255={v}\n'" },
      \ }

let g:editor_config_debug = 3
runtime plugin/editorconfig.vim

execute "source " . escape(TEST_DIR, ' \')  . "/test_runner.vim"

let s:test_desc = {}

function s:new_ec_test(name, ec_file, file, regex)
  let s:test_desc[a:name] = { 'file': escape(a:file, ' {'), 'ec_file': a:ec_file, 'expect': { 'g:ecTestResult': a:regex }}
endfunction

function s:new_ec_test_multiline(name, ec_file, file, regex)
  let myre = substitute(a:regex, '+', '\\+', 'g')
  let s:test_desc[a:name] = { 'file': escape(a:file, ' {'), 'ec_file': a:ec_file, 'expect': { 'g:ecTestResult': myre }}
endfunction

" test repeat sections
call s:new_ec_test_multiline("repeat_sections_ML", "basic.in", "a.a", 'option1=value1[ \t]*[\n\r]+option2=value2[ \t\n\r]*')
call s:new_ec_test_multiline("basic_cascade_ML", "basic.in", "b.b", 'option1=c[ \t]*[\n\r]+option2=b[ \t\n\r]*')

" Tests for whitespace parsing

" test no whitespaces in property assignment
call s:new_ec_test("no_whitespace", "whitespace.in", "test1.c", '^key=value[ \t\n\r]*$')

" test single spaces around equals sign
call s:new_ec_test("single_spaces_around_equals", "whitespace.in", "test2.c", '^key=value[ \t\n\r]*$')

" test multiple spaces around equals sign
call s:new_ec_test("multiple_spaces_around_equals", "whitespace.in", "test3.c", '^key=value[ \t\n\r]*$')

" test spaces before property name
call s:new_ec_test("spaces_before_property_name", "whitespace.in", "test4.c", '^key=value[ \t\n\r]*$')

" test spaces before after property value
call s:new_ec_test("spaces_after_property_value", "whitespace.in", "test5.c", '^key=value[ \t\n\r]*$')

" test blank lines between properties
call s:new_ec_test_multiline("blank_lines_between_properties_ML", "whitespace.in", "test6.c", 'key1=value1[ \t]*[\n\r]+key2=value2[ \t\n\r]*')

" test spaces in section name
" VIM: Doesn't work on Windows. Trailing space is gone after fnamemodify().
" Quote from 'Support for Whitespace characters in File and Folder names for
" Windows 8, Windows RT and Windows Server 2012':
" 'File and Folder names that begin or end with the ASCII Space (0x20) will be
" saved without these characters. ...'
" (https://support.microsoft.com/en-ca/help/2829981/support-for-whitespace-characters-in-file-and-folder-names-for-windows):
if match(fnamemodify(" test 7 ", ':p'), ' $') > 0
    call s:new_ec_test("spaces_in_section_name", "whitespace.in", ' test 7 ', '^key=value[ \t\n\r]*$')
endif

" test spaces before section name are ignored
call s:new_ec_test("spaces_before_section_name", "whitespace.in", "test8.c", '^key=value[ \t\n\r]*$')

" test spaces after section name
call s:new_ec_test("spaces_after_section_name", "whitespace.in", "test9.c", '^key=value[ \t\n\r]*$')

" test spaces at beginning of line between properties
call s:new_ec_test_multiline("spaces_before_middle_property_ML", "whitespace.in", "test10.c", 'key1=value1[ \t]*[\n\r]+key2=value2[ \t]*[\n\r]+key3=value3[ \t\n\r]*')

" test colon seperator with no whitespaces in property assignment
call s:new_ec_test("colon_sep_no_whitespace", "whitespace.in", "test1.d", '^key=value[ \t\n\r]*$')

" test colon seperator with single spaces around equals sign
call s:new_ec_test("colon_sep_single_spaces_around_equals", "whitespace.in", "test2.d", '^key=value[ \t\n\r]*$')

" test colon seperator with multiple spaces around equals sign
call s:new_ec_test("colon_sep_multiple_spaces_around_equals", "whitespace.in", "test3.d", '^key=value[ \t\n\r]*$')

" test colon seperator with spaces before property name
call s:new_ec_test("colon_sep_spaces_before_property_name", "whitespace.in", "test4.d", '^key=value[ \t\n\r]*$')

" test colon seperator with spaces before after property value
call s:new_ec_test("colon_sep_spaces_after_property_value", "whitespace.in", "test5.d", '^key=value[ \t\n\r]*$')


" Tests for comment parsing

" test comments ignored after property name
call s:new_ec_test("comments_after_property", "comments.in", "test1.c", '^key=value[ \t\n\r]*$')

" test comments ignored after section name
call s:new_ec_test("comments_after_section", "comments.in", "test2.c", '^key=value[ \t\n\r]*$')

" test comments ignored before properties
call s:new_ec_test("comment_before_props", "comments.in", "test3.c", '^key=value[ \t\n\r]*$')

" test comments ignored between properties
call s:new_ec_test_multiline("comment_between_props_ML", "comments.in", "test4.c", 'key1=value1[ \t]*[\n\r]+key2=value2[ \t\n\r]*')

" test semicolons at end of property value are included in value
call s:new_ec_test("semicolon_in_property", "comments.in", "test5.c", '^key=value; not comment[ \t\n\r]*$')

" test escaped semicolons are included in property value
" VIM: Bug in original editorconfig parsers (c and py), backslash before ';'
" is returned. Same for us.
call s:new_ec_test("escaped_semicolon_in_property", "comments.in", "test6.c", '^key=value \\; not comment[ \t\n\r]*$')

" test escaped semicolons are included in section names
call s:new_ec_test("escaped_semicolon_in_section", "comments.in", "test;.c", '^key=value[ \t\n\r]*$')

" test octothorpe comments ignored after property name
call s:new_ec_test("octothorpe_comments_after_property", "comments.in", "test7.c", '^key=value[ \t\n\r]*$')

" test octothorpe comments ignored after section name
call s:new_ec_test("octothorpe_comments_after_section", "comments.in", "test8.c", '^key=value[ \t\n\r]*$')

" test octothorpe comments ignored before properties
call s:new_ec_test("octothorpe_comment_before_props", "comments.in", "test9.c", '^key=value[ \t\n\r]*$')

" test octothorpe comments ignored between properties
call s:new_ec_test_multiline("octothorpe_comment_between_props_ML", "comments.in", "test10.c", 'key1=value1[ \t]*[\n\r]+key2=value2[ \t\n\r]*')

" test octothorpe at end of property value are included in value
" VIM: Assert regex corrected ... from ';' to '#'.
" See https://github.com/editorconfig/editorconfig-core-test/issues/24
call s:new_ec_test("octothorpe_in_property", "comments.in", "test11.c", '^key=value# not comment[ \t\n\r]*$')

" test escaped octothorpes are included in property value
" VIM: Assert regex corrected ... from ';' to '#'.
" See https://github.com/editorconfig/editorconfig-core-test/issues/24
" VIM: Bug in original editorconfig parsers (c and py), backslash before '#'
" is returned. Same for us.
call s:new_ec_test("escaped_octothorpe_in_property", "comments.in", "test12.c", '^key=value \\# not comment[ \t\n\r]*$')

" test escaped octothorpes are included in section names
call s:new_ec_test("escaped_octothorpe_in_section", "comments.in", "test\\#.c", '^key=value[ \t\n\r]*$')

" test EditorConfig files with BOM at the head
call s:new_ec_test("bom_at_head", "bom.in", "a.c", '^key=value[ \t\n\r]*$')

" test EditorConfig files with CRLF line separators
call s:new_ec_test("crlf_linesep", "crlf.in", "a.c", '^key=value[ \t\n\r]*$')


" Test max property name and values
call s:new_ec_test("max_property_name", "limits.in", "test1", '^00000000000000000000000000000000000000000000000001=50[ \t\n\r]*$')
call s:new_ec_test("max_property_value", "limits.in", "test2", '^k255=000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001[ \t\n\r]*$')

" Test max section names
call s:new_ec_test("max_section_name_ok", "limits.in", "test3", '^key=value[ \t\n\r]*$')
" VIM: We don't have a "max_section_name". There might be a limit, but I don't
" know where.
"call s:new_ec_test("max_section_name_ignore", "limits.in", "test4", '^[ \t\n\r]*$')


execute "lcd " . s:TEST_FILE_DIR
let g:TEST_COMPARE = 'regex'
if 0 != RunTestSet("editorconfig-core-parser", s:test_desc)
  cq!
else
  quit!
endif

quit!
