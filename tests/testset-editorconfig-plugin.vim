"
" FILE: testset-editorconfig-plugin.vim
"
" ABSTRACT: Tests from editorconfig-plugin-test
"
" https://github.com/editorconfig/editorconfig-plugin-tests
"

let TEST_DIR=expand("<sfile>:h")
let PLUGIN_RTP = TEST_DIR . '/..'

let s:TEST_FILE_DIR=TEST_DIR . '/editorconfig-plugin-tests/test_files/'

let g:editor_config_debug = 3
runtime plugin/editorconfig.vim

execute "source " . escape(TEST_DIR, ' \')  . "/test_runner.vim"

let s:test_desc = {}

" from tests/charset.rst
let s:test_desc['latin1.txt'] = { 'file': 'latin1.txt', 'expect': { '&fileencoding': 'latin1' }}
let s:test_desc['utf-8.txt'] = { 'file': 'utf-8.txt', 'expect': { '&fileencoding': 'utf-8', '&bomb': 0 }}
let s:test_desc['utf-8-bom.txt'] = { 'file': 'utf-8-bom.txt', 'expect': { '&fileencoding': 'utf-8', '&bomb': 1 }}
let s:test_desc['utf-16be.txt'] = { 'file': 'utf-16be.txt', 'expect': { '&fileencoding': 'utf-16' }}
let s:test_desc['utf-16le.txt'] = { 'file': 'utf-16le.txt', 'expect': { '&fileencoding': 'utf-16le' }}

" from tests/end_of_line.rst
let s:test_desc['lf.txt'] = { 'file': 'lf.txt', 'expect': { '&fileformat': 'unix' }}
let s:test_desc['crlf.txt'] = { 'file': 'crlf.txt', 'expect': { '&fileformat': 'dos' }}
let s:test_desc['cr.txt'] = { 'file': 'cr.txt', 'expect': { '&fileformat': 'mac' }}

" from tests/indentation.rst
let s:test_desc['3_space.txt'] = { 'file': '3_space.txt', 'expect': { '&expandtab': 1, '&shiftwidth': 3, '&tabstop': 3 }}
let s:test_desc['4_space.py'] = { 'file': '4_space.py', 'expect': { '&expandtab': 1, '&shiftwidth': 4, '&tabstop': 8 }}
let s:test_desc['space.txt'] = { 'file': 'space.txt', 'expect': { '&expandtab': 1, '&shiftwidth': 0 }}
let s:test_desc['tab.txt'] = { 'file': 'tab.txt', 'expect': { '&expandtab': 0 }}
let s:test_desc['4_tab.txt'] = { 'file': '4_tab.txt', 'expect': { '&expandtab': 0, '&shiftwidth': 4, '&tabstop': 4 }}
let s:test_desc['4_tab_width_of_8.txt'] = { 'file': '4_tab_width_of_8.txt', 'expect': { '&expandtab': 0, '&shiftwidth': 4, '&tabstop': 8 }}

" from tests/insert_final_newline.rst
let s:test_desc['with_newline.txt'] = { 'file': 'with_newline.txt', 'expect': { '&fixendofline': 1 }}
let s:test_desc['without_newline.txt'] =  { 'file': 'without_newline.txt', 'expect': { '&fixendofline': 0 }}

" from tests/trim_trailing_whitespace.rst
" Check if autocmd is installed or not
let s:test_desc['trim.txt'] = { 'file': 'trim.txt', 'expect': { 'match(execute("autocmd EditorConfigTrim"), "TrimTrailingWhiteSpace")>=0': 1 }}
let s:test_desc['no_trim.txt'] = { 'file': 'no_trim.txt', 'expect': { 'match(execute("autocmd EditorConfigTrim"), "TrimTrailingWhiteSpace")>=0': 0 }}

execute "lcd " . s:TEST_FILE_DIR
if 0 != RunTestSet("editorconfig-plugin", s:test_desc)
  cq!
else
  quit!
endif

