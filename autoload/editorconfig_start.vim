" editorconfig.vim: (global plugin) editorconfig support for Vim
" autoload script of editorconfig plugin, see ../plugin/editorconfig.vim
" Version:     0.1
" Last Change: 2019 Apr 12

" The core plugin.
" For documentation see ../doc/editorconfig.vim


" Loader for the core plugin.
" This plugin first checks if the core of the editorconfig plugin is needed
" before actually loading it (by calling a autoload function)
"
" For debugging set the variable g:editor_config_debug to 3. After loading a
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

" Create absolut file name and base-dir to search for .editorconfig files.
" Simple for existing files and non existing files in existing directories.
" More complex for files in none existing directories. This is a real corner
" case, but at least needed for testing.
function! s:GetEditorconfigParameter(fn)
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
function! editorconfig_start#CheckAndHandleEditorConfig(force)

  " allow other filename as '.editorconfig' for testing
  " Variable g:editor_config_file is not documented
  let editor_config_file = get(g:, "editor_config_file", ".editorconfig")

  if !&modifiable
    return
  endif

  let [filename, file_dir] = s:GetEditorconfigParameter(expand('%'))
  if has("win32")
      let filename = substitute(filename, '\\', '/', 'g')
      let file_dir = substitute(file_dir, '\\', '/', 'g')
  endif
  if get(g:, "editor_config_debug", 0) >= 3
    call editorconfig#Debug('Expanded Filename: "%s" -> "%s"', expand('%'), filename)
    call editorconfig#Debug('Basedir: "%s"', file_dir)
    call editorconfig#Debug('Filetype: %s', &filetype)
  endif

  " project base dirs
  if exists("g:editor_config_base_dirs")
    let found = 0
    for basedir in g:editor_config_base_dirs
      if stridx(filename, basedir) == 0
        let found = 1
        break
      endif
    endfor
    if found == 0
      call editorconfig#Debug('Skipped - not in a allowed base dir')
      return
    endif
    unlet found
  endif

  " check blacklist
  if empty(a:force) && exists("g:editor_config_blacklist")
    if !empty(&filetype)
      if has_key(g:editor_config_blacklist, 'filetype')
        for ft in g:editor_config_blacklist.filetype
          if &filetype =~?  glob2regpat(ft)
            call editorconfig#Debug('Skipped - blacklisted filetype: %s', ft)
            return 2
          endif
        endfor
      endif
    endif
    if has_key(g:editor_config_blacklist, 'filename')
      for glob in g:editor_config_blacklist.filename
        if glob[0] != '*'
          let glob = '*/' . glob
        endif
        if filename =~?  glob2regpat(glob)
          call editorconfig#Debug('Skipped - blacklisted file name pattern: %s', glob)
          return 3
        endif
      endfor
    endif
  endif

  let ec_files = findfile(editor_config_file, file_dir . ';', -1)
  let ec_files = filter(ec_files, {i, v -> filereadable(v)})
  if empty(ec_files)
    " no .editorconfig files found - nothing to do
    call editorconfig#Debug('No editorconfig files (%s) found', editor_config_file)
    return 1
  endif
  call editorconfig#Debug('EditorConfig files: %s', ec_files)

  if ! exists('b:editor_config_running')
    try
      let b:editor_config_running = 1
      call editorconfig#HandleEditorConfig(filename, ec_files)
    finally
      unlet b:editor_config_running
    endtry
  endif
  return 0
endfunction

function editorconfig_start#Apply(force)
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
