" editorconfig.vim: (global plugin) editorconfig support for Vim
" autoload script of editorconfig plugin, see ../plugin/editorconfig.vim
" Version:     0.1
" Last Change: 2019 Apr 12
"

" The manage listeners for editorconfig property events
" For documentation see ../doc/editorconfig.vim section "Integrating with the
" Editorconfig Plugin"

let s:listeners = []

" Register a callback
function editorconfiglistener#register(func_ref)
  let idx = index(s:listeners, a:func_ref)
  if idx < 0
    call add(s:listeners, a:func_ref)
  endif
endfunction

" UN-Register a callback
function editorconfiglistener#unregister(func_ref)
  let idx = index(s:listeners, a:func_ref)
  if idx >= 0
    call remove(s:listeners, idx)
  endif
endfunction

" Get the list of registered callbacks
function editorconfiglistener#get()
  return s:listeners
endfunction



