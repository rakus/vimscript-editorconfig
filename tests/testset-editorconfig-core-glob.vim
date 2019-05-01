"
" FILE: testset-editorconfig-core-glob.vim
"
" ABSTRACT: Tests from editorconfig-core-test, section "glob"
"
" See https://github.com/editorconfig/editorconfig-core-test/tree/master/glob
"
" This code is based on test code from the editorconfig-core-test project
" which is Copyright (c) 2011-2018 EditorConfig Team
" See https://github.com/editorconfig/editorconfig-core-test/blob/master/LICENSE.txt
"

" VIM: Ignored test on WINDOWS.
" In all this testcases the filename starts with a '{'. This is somehow
" escaped with a backslash. Needs further investigation.
let s:SkipTestOnWindows = []

let TEST_DIR=expand("<sfile>:h")
let PLUGIN_RTP = TEST_DIR . '/..'

let s:TEST_FILE_DIR=TEST_DIR . '/editorconfig-core-test/glob/'

" Global variable g:ecTestResult defined in test_runner.vim
let g:editor_config_config = {
      \ 'backslash':        { 'execute': "let g:ecTestResult .= 'backslash={v}\n'" },
      \ 'choice':           { 'execute': "let g:ecTestResult .= 'choice={v}\n'" },
      \ 'choice_with_dash': { 'execute': "let g:ecTestResult .= 'choice_with_dash={v}\n'" },
      \ 'close_inside':     { 'execute': "let g:ecTestResult .= 'close_inside={v}\n'" },
      \ 'close_outside':    { 'execute': "let g:ecTestResult .= 'close_outside={v}\n'" },
      \ 'closing':          { 'execute': "let g:ecTestResult .= 'closing={v}\n'" },
      \ 'comma':            { 'execute': "let g:ecTestResult .= 'comma={v}\n'" },
      \ 'empty':            { 'execute': "let g:ecTestResult .= 'empty={v}\n'" },
      \ 'key':              { 'execute': "let g:ecTestResult .= 'key={v}\n'" },
      \ 'key1':             { 'execute': "let g:ecTestResult .= 'key1={v}\n'" },
      \ 'key2':             { 'execute': "let g:ecTestResult .= 'key2={v}\n'" },
      \ 'key3':             { 'execute': "let g:ecTestResult .= 'key3={v}\n'" },
      \ 'key4':             { 'execute': "let g:ecTestResult .= 'key4={v}\n'" },
      \ 'keyb':             { 'execute': "let g:ecTestResult .= 'keyb={v}\n'" },
      \ 'keyc':             { 'execute': "let g:ecTestResult .= 'keyc={v}\n'" },
      \ 'nested':           { 'execute': "let g:ecTestResult .= 'nested={v}\n'" },
      \ 'number':           { 'execute': "let g:ecTestResult .= 'number={v}\n'" },
      \ 'patterns':         { 'execute': "let g:ecTestResult .= 'patterns={v}\n'" },
      \ 'range':            { 'execute': "let g:ecTestResult .= 'range={v}\n'" },
      \ 'range_and_choice': { 'execute': "let g:ecTestResult .= 'range_and_choice={v}\n'" },
      \ 'slash_half_open':  { 'execute': "let g:ecTestResult .= 'slash_half_open={v}\n'" },
      \ 'slash_inside':     { 'execute': "let g:ecTestResult .= 'slash_inside={v}\n'" },
      \ 'unmatched':        { 'execute': "let g:ecTestResult .= 'unmatched={v}\n'" },
      \ 'words':            { 'execute': "let g:ecTestResult .= 'words={v}\n'" }
      \ }

let g:editor_config_debug = 3
runtime plugin/editorconfig.vim

execute "source " . escape(TEST_DIR, ' \')  . "/test_runner.vim"
execute "source " . escape(TEST_DIR, ' \')  . "/cmake_test_def.vim"

let g:test_desc = {}

" Tests for *

" matches a single characters
call New_ec_test_multiline("star_single_ML", "star.in", "ace.c", 'key=value[ \t\n\r]+keyc=valuec[ \t\n\r]*')

" matches zero characters
call New_ec_test_multiline("star_zero_ML", "star.in", "ae.c", 'key=value[ \t\n\r]+keyc=valuec[ \t\n\r]*')

" matches multiple characters
call New_ec_test_multiline("star_multiple_ML", "star.in", "abcde.c", 'key=value[ \t\n\r]+keyc=valuec[ \t\n\r]*')

" does not match path separator
call New_ec_test("star_over_slash", "star.in", "a/e.c", '^[ \t\n\r]*keyc=valuec[ \t\n\r]*$')

" star after a slash
call New_ec_test_multiline("star_after_slash_ML", "star.in", "Bar/foo.txt", 'keyb=valueb[ \t\n\r]+keyc=valuec[ \t\n\r]*')

" star matches a dot file after slash
call New_ec_test_multiline("star_matches_dot_file_after_slash_ML", "star.in", "Bar/.editorconfig", 'keyb=valueb[ \t\n\r]+keyc=valuec[ \t\n\r]*')

" star matches a dot file
call New_ec_test("star_matches_dot_file", "star.in", ".editorconfig", '^keyc=valuec[ \t\n\r]*$')

" Tests for ?

" matches a single character
call New_ec_test("question_single", "question.in", "some.c", '^key=value[ \t\n\r]*$')

" does not match zero characters
call New_ec_test("question_zero", "question.in", "som.c", '^[ \t\n\r]*$')

" does not match multiple characters
call New_ec_test("question_multiple", "question.in", "something.c", '^[ \t\n\r]*$')


" Tests for [ and ]

" close bracket inside
call New_ec_test("brackets_close_inside", "brackets.in", "].g", '^close_inside=true[ \t\n\r]*$')

" close bracket outside
call New_ec_test("brackets_close_outside", "brackets.in", "b].g", '^close_outside=true[ \t\n\r]*$')

" negative close bracket inside
call New_ec_test("brackets_nclose_inside", "brackets.in", "c.g", '^close_inside=false[ \t\n\r]*$')

" negative close bracket outside
call New_ec_test("brackets_nclose_outside", "brackets.in", "c].g", '^close_outside=false[ \t\n\r]*$')

" character choice
call New_ec_test("brackets_choice", "brackets.in", "a.a", '^choice=true[ \t\n\r]*$')

" character choice 2
call New_ec_test("brackets_choice2", "brackets.in", "c.a", '^[ \t\n\r]*$')

" negative character choice
call New_ec_test("brackets_nchoice", "brackets.in", "c.b", '^choice=false[ \t\n\r]*$')

" negative character choice 2
call New_ec_test("brackets_nchoice2", "brackets.in", "a.b", '^[ \t\n\r]*$')

" character range
call New_ec_test("brackets_range", "brackets.in", "f.c", '^range=true[ \t\n\r]*$')

" character range 2
call New_ec_test("brackets_range2", "brackets.in", "h.c", '^[ \t\n\r]*$')

" negative character range
call New_ec_test("brackets_nrange", "brackets.in", "h.d", '^range=false[ \t\n\r]*$')

" negative character range 2
call New_ec_test("brackets_nrange2", "brackets.in", "f.d", '^[ \t\n\r]*$')

" range and choice
call New_ec_test("brackets_range_and_choice", "brackets.in", "e.e", '^range_and_choice=true[ \t\n\r]*$')

" character choice with a dash
call New_ec_test("brackets_choice_with_dash", "brackets.in", "-.f", '^choice_with_dash=true[ \t\n\r]*$')

" slash inside brackets
call New_ec_test("brackets_slash_inside1", "brackets.in", "ab/cd.i", '^[ \t\n\r]*$')
call New_ec_test("brackets_slash_inside2", "brackets.in", "abecd.i", '^[ \t\n\r]*$')
call New_ec_test("brackets_slash_inside3", "brackets.in", "ab[e/]cd.i", '^slash_inside=true[ \t\n\r]*$')
call New_ec_test("brackets_slash_inside4", "brackets.in", "ab[/c", '^slash_half_open=true[ \t\n\r]*$')

" Tests for { and }

" word choice
call New_ec_test("braces_word_choice1", "braces.in", "test.py", '^choice=true[ \t\n\r]*$')
call New_ec_test("braces_word_choice2", "braces.in", "test.js", '^choice=true[ \t\n\r]*$')
call New_ec_test("braces_word_choice3", "braces.in", "test.html", '^choice=true[ \t\n\r]*$')
call New_ec_test("braces_word_choice4", "braces.in", "test.pyc", '^[ \t\n\r]*$')

" single choice
call New_ec_test("braces_single_choice", "braces.in", "{single}.b", '^choice=single[ \t\n\r]*$')
call New_ec_test("braces_single_choice_negative", "braces.in", ".b", '^[ \t\n\r]*$')

" empty choice
call New_ec_test("braces_empty_choice", "braces.in", "{}.c", '^empty=all[ \t\n\r]*$')
call New_ec_test("braces_empty_choice_negative", "braces.in", ".c", '^[ \t\n\r]*$')

" choice with empty word
call New_ec_test("braces_empty_word1", "braces.in", "a.d", '^empty=word[ \t\n\r]*$')
call New_ec_test("braces_empty_word2", "braces.in", "ab.d", '^empty=word[ \t\n\r]*$')
call New_ec_test("braces_empty_word3", "braces.in", "ac.d", '^empty=word[ \t\n\r]*$')
call New_ec_test("braces_empty_word4", "braces.in", "a,.d", '^[ \t\n\r]*$')

" choice with empty words
call New_ec_test("braces_empty_words1", "braces.in", "a.e", '^empty=words[ \t\n\r]*$')
call New_ec_test("braces_empty_words2", "braces.in", "ab.e", '^empty=words[ \t\n\r]*$')
call New_ec_test("braces_empty_words3", "braces.in", "ac.e", '^empty=words[ \t\n\r]*$')
call New_ec_test("braces_empty_words4", "braces.in", "a,.e", '^[ \t\n\r]*$')

" no closing brace
call New_ec_test("braces_no_closing", "braces.in", "{.f", '^closing=false[ \t\n\r]*$')
call New_ec_test("braces_no_closing_negative", "braces.in", ".f", '^[ \t\n\r]*$')

" nested braces
call New_ec_test("braces_nested1", "braces.in", "word,this}.g", '^[ \t\n\r]*$')
call New_ec_test("braces_nested2", "braces.in", "{also,this}.g", '^[ \t\n\r]*$')
call New_ec_test("braces_nested3", "braces.in", "word.g", '^nested=true[ \t\n\r]*$')
call New_ec_test("braces_nested4", "braces.in", "{also}.g", '^nested=true[ \t\n\r]*$')
call New_ec_test("braces_nested5", "braces.in", "this.g", '^nested=true[ \t\n\r]*$')

" closing inside beginning
call New_ec_test("braces_closing_in_beginning", "braces.in", "{},b}.h", '^closing=inside[ \t\n\r]*$')

" missing closing braces
call New_ec_test("braces_unmatched1", "braces.in", "{{,b,c{d}.i", '^unmatched=true[ \t\n\r]*$')
call New_ec_test("braces_unmatched2", "braces.in", "{.i", '^[ \t\n\r]*$')
call New_ec_test("braces_unmatched3", "braces.in", "b.i", '^[ \t\n\r]*$')
call New_ec_test("braces_unmatched4", "braces.in", "c{d.i", '^[ \t\n\r]*$')
call New_ec_test("braces_unmatched5", "braces.in", ".i", '^[ \t\n\r]*$')

" escaped comma
call New_ec_test("braces_escaped_comma1", "braces.in", "a,b.txt", '^comma=yes[ \t\n\r]*$')
call New_ec_test("braces_escaped_comma2", "braces.in", "a.txt", '^[ \t\n\r]*$')
call New_ec_test("braces_escaped_comma3", "braces.in", "cd.txt", '^comma=yes[ \t\n\r]*$')

" escaped closing brace
call New_ec_test("braces_escaped_brace1", "braces.in", "e.txt", '^closing=yes[ \t\n\r]*$')
call New_ec_test("braces_escaped_brace2", "braces.in", "}.txt", '^closing=yes[ \t\n\r]*$')
call New_ec_test("braces_escaped_brace3", "braces.in", "f.txt", '^closing=yes[ \t\n\r]*$')

" escaped backslash
call New_ec_test("braces_escaped_backslash1", "braces.in", "g.txt", '^backslash=yes[ \t\n\r]*$')
if !has("win32") && !has("win32unix") " this case is impossible on Windows.
  call New_ec_test("braces_escaped_backslash2", "braces.in", "\\\\.txt", '^backslash=yes[ \t\n\r]*$')
endif
call New_ec_test("braces_escaped_backslash3", "braces.in", "i.txt", '^backslash=yes[ \t\n\r]*$')

" patterns nested in braces
call New_ec_test("braces_patterns_nested1", "braces.in", "some.j", '^patterns=nested[ \t\n\r]*$')
call New_ec_test("braces_patterns_nested2", "braces.in", "abe.j", '^patterns=nested[ \t\n\r]*$')
call New_ec_test("braces_patterns_nested3", "braces.in", "abf.j", '^patterns=nested[ \t\n\r]*$')
call New_ec_test("braces_patterns_nested4", "braces.in", "abg.j", '^[ \t\n\r]*$')
call New_ec_test("braces_patterns_nested5", "braces.in", "ace.j", '^patterns=nested[ \t\n\r]*$')
call New_ec_test("braces_patterns_nested6", "braces.in", "acf.j", '^patterns=nested[ \t\n\r]*$')
call New_ec_test("braces_patterns_nested7", "braces.in", "acg.j", '^[ \t\n\r]*$')
call New_ec_test("braces_patterns_nested8", "braces.in", "abce.j", '^patterns=nested[ \t\n\r]*$')
call New_ec_test("braces_patterns_nested9", "braces.in", "abcf.j", '^patterns=nested[ \t\n\r]*$')
call New_ec_test("braces_patterns_nested10", "braces.in", "abcg.j", '^[ \t\n\r]*$')
call New_ec_test("braces_patterns_nested11", "braces.in", "ae.j", '^[ \t\n\r]*$')
call New_ec_test("braces_patterns_nested12", "braces.in", ".j", '^[ \t\n\r]*$')

" numeric brace range
call New_ec_test("braces_numeric_range1", "braces.in", "1", '^[ \t\n\r]*$')
call New_ec_test("braces_numeric_range2", "braces.in", "3", '^number=true[ \t\n\r]*$')
call New_ec_test("braces_numeric_range3", "braces.in", "15", '^number=true[ \t\n\r]*$')
call New_ec_test("braces_numeric_range4", "braces.in", "60", '^number=true[ \t\n\r]*$')
call New_ec_test("braces_numeric_range5", "braces.in", "5a", '^[ \t\n\r]*$')
call New_ec_test("braces_numeric_range6", "braces.in", "120", '^number=true[ \t\n\r]*$')
call New_ec_test("braces_numeric_range7", "braces.in", "121", '^[ \t\n\r]*$')
call New_ec_test("braces_numeric_range8", "braces.in", "060", '^[ \t\n\r]*$')

" alphabetical brace range: letters should not be considered for ranges
call New_ec_test("braces_alpha_range1", "braces.in", "{aardvark..antelope}", '^words=a[ \t\n\r]*$')
call New_ec_test("braces_alpha_range2", "braces.in", "a", '^[ \t\n\r]*$')
call New_ec_test("braces_alpha_range3", "braces.in", "aardvark", '^[ \t\n\r]*$')
call New_ec_test("braces_alpha_range4", "braces.in", "agreement", '^[ \t\n\r]*$')
call New_ec_test("braces_alpha_range5", "braces.in", "antelope", '^[ \t\n\r]*$')
call New_ec_test("braces_alpha_range6", "braces.in", "antimatter", '^[ \t\n\r]*$')


" Tests for **

" test EditorConfig files with UTF-8 characters larger than 127
call New_ec_test("utf_8_char", "utf8char.in", "中文.txt", '^key=value[ \t\n\r]*$')

" matches over path separator
call New_ec_test("star_star_over_separator1", "star_star.in", "a/z.c", '^key1=value1[ \t\n\r]*$')
call New_ec_test("star_star_over_separator2", "star_star.in", "amnz.c", '^key1=value1[ \t\n\r]*$')
call New_ec_test("star_star_over_separator3", "star_star.in", "am/nz.c", '^key1=value1[ \t\n\r]*$')
call New_ec_test("star_star_over_separator4", "star_star.in", "a/mnz.c", '^key1=value1[ \t\n\r]*$')
call New_ec_test("star_star_over_separator5", "star_star.in", "amn/z.c", '^key1=value1[ \t\n\r]*$')
call New_ec_test("star_star_over_separator6", "star_star.in", "a/mn/z.c", '^key1=value1[ \t\n\r]*$')

call New_ec_test("star_star_over_separator7", "star_star.in", "b/z.c", '^key2=value2[ \t\n\r]*$')
call New_ec_test("star_star_over_separator8", "star_star.in", "b/mnz.c", '^key2=value2[ \t\n\r]*$')
call New_ec_test("star_star_over_separator9", "star_star.in", "b/mn/z.c", '^key2=value2[ \t\n\r]*$')
call New_ec_test("star_star_over_separator10", "star_star.in", "bmnz.c", '^[ \t\n\r]*$')
call New_ec_test("star_star_over_separator11", "star_star.in", "bm/nz.c", '^[ \t\n\r]*$')
call New_ec_test("star_star_over_separator12", "star_star.in", "bmn/z.c", '^[ \t\n\r]*$')

call New_ec_test("star_star_over_separator13", "star_star.in", "c/z.c", '^key3=value3[ \t\n\r]*$')
call New_ec_test("star_star_over_separator14", "star_star.in", "cmn/z.c", '^key3=value3[ \t\n\r]*$')
call New_ec_test("star_star_over_separator15", "star_star.in", "c/mn/z.c", '^key3=value3[ \t\n\r]*$')
call New_ec_test("star_star_over_separator16", "star_star.in", "cmnz.c", '^[ \t\n\r]*$')
call New_ec_test("star_star_over_separator17", "star_star.in", "cm/nz.c", '^[ \t\n\r]*$')
call New_ec_test("star_star_over_separator18", "star_star.in", "c/mnz.c", '^[ \t\n\r]*$')

call New_ec_test("star_star_over_separator19", "star_star.in", "d/z.c", '^key4=value4[ \t\n\r]*$')
call New_ec_test("star_star_over_separator20", "star_star.in", "d/mn/z.c", '^key4=value4[ \t\n\r]*$')
call New_ec_test("star_star_over_separator21", "star_star.in", "dmnz.c", '^[ \t\n\r]*$')
call New_ec_test("star_star_over_separator22", "star_star.in", "dm/nz.c", '^[ \t\n\r]*$')
call New_ec_test("star_star_over_separator23", "star_star.in", "d/mnz.c", '^[ \t\n\r]*$')
call New_ec_test("star_star_over_separator24", "star_star.in", "dmn/z.c", '^[ \t\n\r]*$')

execute "cd " . s:TEST_FILE_DIR
let g:TEST_COMPARE = 'regex'
if 0 != RunTestSet("editorconfig-core-glob", g:test_desc)
  cq!
else
  quit!
endif

