" editorconfig.vim: (global plugin) editorconfig support for Vim
"
" Maintainer:  Ralf Schandl
" Version:     0.1
" Last Change: 2019 Apr 12
" Repository:  TBD
"

if exists('g:loaded_vimscript_ec')
  finish
endif
let g:loaded_vimscript_ec = 1


command -bang EditorConfigApply  call editorconfig_start#Apply(<q-bang>)
command       EditorConfigStatus call editorconfig#EditorConfigStatus()

augroup EditorConfig
  autocmd!
  autocmd BufNewFile,BufReadPost * nested  call editorconfig_start#CheckAndHandleEditorConfig('')
augroup END

