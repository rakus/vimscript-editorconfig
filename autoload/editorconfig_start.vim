" editorconfig.vim: (global plugin) editorconfig support for Vim
" autoload script of editorconfig plugin, see ../plugin/editorconfig.vim
" Version:     0.1
" Last Change: 2019 Aug 23

" The core plugin.
" For documentation see ../doc/editorconfig.vim

" TODO: delete in near future
let s:found_old_config = ""
if exists("g:editor_config_base_dirs")
  let s:found_old_config .= " g:editor_config_base_dirs"
endif
if exists("g:editor_config_blacklist")
  let s:found_old_config .= " g:editor_config_blacklist"
endif
if exists("g:editor_config_blacklist_filetype")
  let s:found_old_config .= " g:editor_config_blacklist_filetype"
endif
if exists("g:editor_config_blacklist_name")
  let s:found_old_config .= " g:editor_config_blacklist_name"
endif
if exists("g:editor_config_config")
  let s:found_old_config .= " g:editor_config_config"
endif
if exists("g:editor_config_debug")
  let s:found_old_config .= " g:editor_config_debug"
endif
if exists("g:editor_config_file")
  let s:found_old_config .= " g:editor_config_file"
endif
if exists("g:editor_config_info")
  let s:found_old_config .= " g:editor_config_info"
endif
if exists("g:editor_config_verbose")
  let s:found_old_config .= " g:editor_config_verbose"
endif

if !empty(s:found_old_config)
  echomsg "WARNING: found old confiuguration names: " . s:found_old_config
  echomsg "See :help editorconfig-customization for new names and deleted config"
endif





" Loader for the core plugin.
" This plugin first checks if the core of the editorconfig plugin is needed
" before actually loading it (by calling a autoload function)
"
" For debugging set the variable g:editorconfig_debug to 3. After loading a
" file check the output of `:EditorConfig status`.
"
" For documentation see ../doc/editorconfig.vim

if has("win32") && ! has("win32unix")
  let s:FSEP = '\'
  let s:DEL_DOTS_RE = '[^\\]\+\\\.\.\+\(\\\|$\)'
else
  let s:FSEP = '/'
  let s:DEL_DOTS_RE = '[^/]\+/\.\.\+\(/\|$\)'
endif

"
" Proxy for editorconfig#Debug to prevent loading of editorconfig.vim,
" if g:editorconfig_debug is not set to the appropriate level.
"
function! s:Debug(level, msg, ...) abort
  if get(g:, 'editorconfig_debug', 0) >= a:level
    call call("editorconfig#Debug", [ a:level, a:msg ] + a:000)
  endif
endfunction

" Create absolut file name and base-dir to search for .editorconfig files.
" Simple for existing files and non existing files in existing directories.
" More complex for files in none existing directories. This is a real corner
" case, but at least needed for testing.
function! s:GetEditorconfigParameter(fn) abort
  if filereadable(a:fn) || isdirectory(fnamemodify(a:fn, ':h'))
    let fn = fnamemodify(a:fn, ':p')
    let dn = fnamemodify(a:fn, ':p:h')
  else
    let pd = fnamemodify(a:fn, ':h')
    while !isdirectory(pd)
      let pd = fnamemodify(pd, ':h')
    endwhile
      echo pd
    if pd == '.'
      let fn = getcwd() . s:FSEP . a:fn
      let dn = getcwd()
    elseif pd == fnamemodify(pd, ':h')
      let fn = a:fn
      let dn = pd
    else
      let tail = strpart(a:fn, strlen(pd)+1)
      let pd = fnamemodify(pd, ':p')
      let pd = substitute(pd, s:DEL_DOTS_RE, '', 'g')
      let fn = pd . tail
      let dn = pd
    endif
  endif
  "let fn = substitute(fn, '//\+', '/', 'g')
  if has("win32")
    " On Windows file might have a trailing backspace, then upward search does
    " not work.
    let dn = substitute(dn, '\\$', '', '')
  endif
  return [ fn , dn ]
endfunc

" Check if editorconfig should be applied for the current file, if yes do it!
" Checks are:
" - Skip for nonmodifiable.
" - Skip for blacklisted files by name or filetype
" - Check that a .editorconfig file is available in the current or a parent
"   dirrectory.
function! editorconfig_start#CheckAndHandleEditorConfig(force) abort

  " allow other filename as '.editorconfig' for testing
  " Variable g:editorconfig_file is not documented
  let editorconfig_file = get(g:, "editorconfig_file", ".editorconfig")

  if !&modifiable
    return
  endif

  let [filename, file_dir] = s:GetEditorconfigParameter(expand('%'))
  if has("win32")
      let filename = substitute(filename, '\\', '/', 'g')
      let file_dir = substitute(file_dir, '\\', '/', 'g')
  endif
  if get(g:, "editorconfig_debug", 0) >= 3
    call s:Debug(3, 'Expanded Filename: "%s" -> "%s"', expand('%'), filename)
    call s:Debug(3, 'Basedir: "%s"', file_dir)
    call s:Debug(3, 'Filetype: %s', &filetype)
  endif

  " project base dirs
  let editorconfig_base_dirs = get(g:, "editorconfig_base_dirs", [])
  if empty(a:force) && !empty(editorconfig_base_dirs)
    let found = 0
    for basedir in editorconfig_base_dirs
      if stridx(filename, basedir) == 0
        let found = 1
        break
      endif
    endfor
    if found == 0
      call s:Debug(1, 'Skipped - not in a allowed base dir')
      return
    endif
    unlet found
  endif

  " check blacklist
  if empty(a:force)
    if !empty(&filetype)
      for ft in get(g:, "editorconfig_blacklist_filetype", [])
        if &filetype =~?  glob2regpat(ft)
          call s:Debug(1, 'Skipped - blacklisted filetype: %s', ft)
          return 2
        endif
      endfor
    endif
    for glob in get(g:, "editorconfig_blacklist_name", [])
      if glob[0] != '*'
        let glob = '*/' . glob
      endif
      if filename =~?  glob2regpat(glob)
          call s:Debug(1, 'Skipped - blacklisted file name pattern: %s', glob)
        return 3
      endif
    endfor
  endif

  let ec_files = findfile(editorconfig_file, file_dir . ';', -1)
  let ec_files = filter(ec_files, {i, v -> filereadable(v)})
  if empty(ec_files)
    " no .editorconfig files found - nothing to do
    call s:Debug(1, 'No editorconfig files (%s) found', editorconfig_file)
    return 1
  endif
  call s:Debug(1, 'EditorConfig files: %s', ec_files)

  if ! exists('b:editorconfig_running')
    try
      let b:editorconfig_running = 1
      call editorconfig#HandleEditorConfig(filename, ec_files)
    finally
      unlet b:editorconfig_running
    endtry
  endif
  return 0
endfunction

function editorconfig_start#Apply(force) abort
  let rc =  editorconfig_start#CheckAndHandleEditorConfig(a:force)
  if rc == 0
    echo "EditorConfig applied"
  elseif rc == 1
    echo "EditorConfig NOT applied - no .editorconfig files found"
  elseif rc == 2
    echo "EditorConfig NOT applied - filetype blacklisted"
  elseif rc == 3
    echo "EditorConfig NOT applied - filename blacklisted"
  else
    echo "EditorConfig NOT applied - unknown reason: " . rc
  endif
endfunction
