"
" FILE: testset-editorconfig-core-properties.vim
"
" ABSTRACT: Tests from editorconfig-core-test, section "properties"
"
" https://github.com/editorconfig/editorconfig-core-test/tree/master/properties
"
" This code is based on test code from the editorconfig-core-test project
" which is Copyright (c) 2011-2018 EditorConfig Team
" See https://github.com/editorconfig/editorconfig-core-test/blob/master/LICENSE.txt
"

" NOTE: This can't use the cmake style test (new_ec_test,
" new_ec_test_multiline), as the plugin can't guarantee the order of
" properties.

let TEST_DIR=expand("<sfile>:h")
let PLUGIN_RTP = TEST_DIR . '/..'

let s:TEST_FILE_DIR=TEST_DIR . '/editorconfig-core-test/properties/'

" Global variable g:ecTestResultDict defined in test_runner.vim
let g:editor_config_config = {
      \ 'trim_trailing_whitespace': { 'lower_case': v:true, 'execute': 'let b:trim_trailing_whitespace="{v}"' },
      \ 'test_property': { 'execute': 'let g:ecTestResultDict["test_property"]="{v}"' },
      \ 'testproperty': { 'execute': 'let g:ecTestResultDict["testproperty"]="{v}"' }
      \ }

let g:editor_config_debug = 3
runtime plugin/editorconfig.vim

execute "source " . escape(TEST_DIR, ' \')  . "/test_runner.vim"

let s:test_desc = {}

" test tab_width default
let s:test_desc['tab_width_default_ML']={ 'ec_file':'tab_width_default.in', 'file':'test.c',
      \ 'expect': { '&l:shiftwidth': 4, '&l:expandtab': 1, '&l:tabstop': 4 }}

" Tab_width should not be set to any value if indent_size is "tab" and
" tab_width is not set
let s:test_desc['tab_width_default_indent_size_tab_ML']={ 'ec_file':'tab_width_default.in', 'file':'test2.c',
      \ 'expect': { '&l:shiftwidth': 0, '&l:expandtab': 0 }}

" Test indent_size default. When indent_style is "tab", indent_size defaults to
" "tab".
let s:test_desc['indent_size_default_ML']={ 'ec_file':'indent_size_default.in', 'file':'test.c',
      \ 'expect': { '&l:shiftwidth': 8, '&l:expandtab': 0 }}

" Test indent_size default. When indent_style is "tab", indent_size should have
" no default value for version prior than 0.9.0.
"let s:test_desc['indent_size_default_pre_0_9_0'] = { 'ec_file': 'indent_size_default.in', 'file': 'test.c',
"         \ 'expect': { '&l:expandtab': 0 }}

" Test indent_size default. When indent_style is "space", indent_size has no
" default value.
" VIM: default shiftwidth = 8
let s:test_desc['indent_size_default_space'] = { 'ec_file': 'indent_size_default.in', 'file': 'test2.c',
      \ 'expect': { '&l:expandtab': 1, '&l:shiftwidth': 8 }}

" Test indent_size default. When indent_style is "tab" and tab_width is set,
" indent_size should default to tab_width
" VIM: In Vim `shiftwidth` is set to 0, as it then defaults to tabstop. See
" `:help shiftwidth`. The original test expected shiftwidth == 2.
let s:test_desc['indent_size_default_with_tab_width_ML'] = { 'ec_file': 'indent_size_default.in', 'file': 'test3.c',
      \ 'expect': { '&l:shiftwidth': 0, '&l:expandtab': 0, '&l:tabstop': 2 }}

" test that same property values are lowercased (v0.9.0 properties)
let s:test_desc['lowercase_values1_ML']={ 'ec_file':'lowercase_values.in', 'file':'test1.c',
      \ 'expect': { '&l:fileformat': 'dos', '&l:expandtab': 1 }}

" test that same property values are lowercased (v0.9.0 properties)
let s:test_desc['lowercase_values2_ML']={ 'ec_file':'lowercase_values.in', 'file':'test2.c',
      \ 'expect': { '&l:fileencoding': 'utf-8',  '&l:fixendofline': 1, 'b:trim_trailing_whitespace': 'false' }}

" test that same property values are not lowercased
let s:test_desc['lowercase_values3'] = { 'ec_file': 'lowercase_values.in', 'file': 'test3.c',
      \ 'expect': { 'g:ecTestResultDict["test_property"]': 'TestValue' }}

" test that all property names are lowercased
let s:test_desc['lowercase_names'] = { 'ec_file': 'lowercase_names.in', 'file': 'test.c',
      \ 'expect': { 'g:ecTestResultDict["testproperty"]': 'testvalue' }}

execute "lcd " . s:TEST_FILE_DIR
"let g:TEST_COMPARE = 'regex'
if 0 != RunTestSet("editorconfig-core-properties", s:test_desc)
  cq!
else
  quit!
endif
