" editorconfig.vim: (global plugin) editorconfig support for Vim
" autoload script of editorconfig plugin, see ../plugin/editorconfig.vim
" Version:     0.1
" Last Change: 2019 Apr 12

" The core plugin.
" For documentation see ../doc/editorconfig.vim

" Supported encoding.
" Note: the last one 'utf-16be' is not named in the Vim help, but works
" anyway. At least on Linux.
let s:enc_names = [ 'latin1' , 'iso-8859-n' , 'koi8-r' , 'koi8-u' , 'macroman' , 'cp437' ,
      \ 'cp737' , 'cp775' , 'cp850' , 'cp852' , 'cp855' , 'cp857' , 'cp860' ,
      \ 'cp861' , 'cp862' , 'cp863' , 'cp865' , 'cp866' , 'cp869' , 'cp874' ,
      \ 'cp1250' , 'cp1251' , 'cp1253' , 'cp1254' , 'cp1255' , 'cp1256' ,
      \ 'cp1257' , 'cp1258' , 'cp932' , 'euc-jp' , 'sjis' , 'cp949' , 'euc-kr' ,
      \ 'cp936' , 'euc-cn' , 'cp950' , 'big5' , 'euc-tw' , 'utf-8' , 'ucs-2' ,
      \ 'ucs-2le' , 'utf-16', 'utf-16le' , 'ucs-4' , 'ucs-4le', 'utf-8-bom',
      \ 'utf-16be' ]

let s:enc_re = [ '^8bit-\S\+$', '^cp\d\+$', '^2byte-\S\+$' ]

" cache to store glob to regex translations
let s:glob2re_cache = {}

" checks hat the value is a integer > 0
" throws exception if not
function! s:PositiveInteger(name, value)
  let int = str2nr(a:value)
  if int <= 0
    throw "EditorConfig: Invalid " . a:name . ": \"" . a:value . "\""
  endif
  return int
endfunction

" Checks that indent_size is either 'tab' or a integer > 0
function! s:ProcessIndentSize(name, value)
  if 'tab' == a:value
    return 0
  else
    return s:PositiveInteger(a:name, a:value)
  endif
endfunction

" Checks that max_line_length is either 'off' or a integer > 0
function! s:MaxLineLength(name, value)
  if a:value == 'off'
    " TODO: Or return 0?
    return &l:textwidth
  else
    return s:PositiveInteger(a:name, a:value)
  endif
endfunction

" Function to trim trailing whitespaces before saving the file.
" Called via autocmd, see InstallTrimTrailingSpaces below.
function! s:TrimTrailingWhiteSpace()
  let save_pos = winsaveview()
  try
    keeppattern %s/\s\+$//e
  finally
    call winrestview(save_pos)
  endtry
endfunction

" Install the autocmd to trim trailing whitespaces before save
function! s:InstallTrimTrailingSpaces(unused)
  augroup EditorConfigTrim
    autocmd! * <buffer>
    autocmd BufWritePre <buffer> :call s:TrimTrailingWhiteSpace()
  augroup END
  call editorconfig#Info("Installed autocmd TrimTrailingWhiteSpace")
endfunction

" Validate that the given encoding is supported by Vim
" If not, throws exception
function! s:ValidateEncoding(unused, encoding)
  if index(s:enc_names, a:encoding) > -1
    return a:encoding
  endif
  for re in s:enc_re
    if a:encoding =~ re
      return a:encoding
    endif
  endfor
  throw "EditorConfig: Unsupported encoding: " . a:encoding
endfunction

" Sets the file encoding
function! s:FileEncoding(encoding)
  let fenc = a:encoding
  if fenc == 'utf-8-bom'
    let fenc = 'utf-8'
  endif
  if fenc != &l:fileencoding
    call editorconfig#Info("Changed fileencoding from " . &l:fileencoding . " to " . fenc)
    let &l:fileencoding = fenc
    " TODO: Or should we reload the file with the given encoding
    " if Vim decided to choose another?
    "if filereadable(expand('%'))
    "  execute "e ++enc=" . fenc
    "  call editorconfig#Info("Reload with encoding " . fenc)
    "else
    "  call editorconfig#Info("Set fileencoding to " . fenc)
    "  let &l:fileencoding = fenc
    "endif
  else
    call editorconfig#Info("Fileencoding already " . fenc)
  endif

  " TODO: Is this the only case to set a bom?
  if a:encoding =~ '.*-bom$'
    setlocal bomb
    call editorconfig#Info("Setting byte-order-mark")
  endif
endfunc

" dictionary of supported properties
" see :help editorconfig-extending for details
let s:editor_config_config_default = {
      \ 'indent_style': {
      \   'execute': {
      \     'tab': 'setlocal noexpandtab',
      \     'space': 'setlocal expandtab'
      \   }
      \ },
      \ 'indent_size': {
      \   'lower_case': v:true,
      \   'value_process': funcref('s:ProcessIndentSize'),
      \   'execute': 'setlocal shiftwidth={v} softtabstop={v}'
      \ },
      \ 'tab_width': {
      \   'lower_case': v:true,
      \   'value_process': funcref('s:PositiveInteger'),
      \   'execute': 'let &l:tabstop = {v}'
      \ },
      \ 'end_of_line': {
      \   'execute': {
      \     'lf': 'setlocal fileformat=unix',
      \     'cr': 'setlocal fileformat=mac',
      \     'crlf': 'setlocal fileformat=dos'
      \   },
      \ },
      \ 'trim_trailing_whitespace': {
      \   'execute': {
      \     'true': funcref('s:InstallTrimTrailingSpaces'),
      \     'false': ''
      \   }
      \ },
      \ 'insert_final_newline': {
      \   'execute': {
      \     'true': 'setlocal fixendofline',
      \     'false': 'setlocal nofixendofline'
      \   }
      \ },
      \ 'charset': {
      \   'lower_case': v:true,
      \   'value_process': funcref('s:ValidateEncoding'),
      \   'execute': funcref('s:FileEncoding')
      \ },
      \ 'max_line_length': {
      \   'lower_case': v:true,
      \   'value_process': funcref('s:MaxLineLength'),
      \   'execute': 'setlocal textwidth={v}'
      \ },
      \ 'spell_lang': {
      \   'execute': 'setlocal spelllang={v}'
      \ },
      \ 'spell_check': {
      \   'execute': {
      \     'true': 'setlocal spell',
      \     'false': 'setlocal nospell'
      \   }
      \ }
      \}

let s:editor_config_config = s:editor_config_config_default

if exists('g:editor_config_config')
  call extend(s:editor_config_config, g:editor_config_config)
endif

" Add msg to info list
function! editorconfig#Info(msg)
  call add(b:editor_config, a:msg)
endfunction
" Add msg to warning list
function! editorconfig#Warning(msg)
  call add(b:editor_config_warning, a:msg)
endfunction
" Add msg to info list, if debug enabled
function! editorconfig#Debug(msg, ...)
  if get(g:, 'editor_config_debug', 0) > 0
    if !exists("b:editor_config")
      let b:editor_config = []
    endif
    call add(b:editor_config, "DEBUG: " . call('printf', [a:msg] +  a:000))
  endif
endfunction

" Add editorconfig file name, section and msg to warning list
function! s:ParserWarning(ctx, msg)
  call add(b:editor_config_warning, a:ctx.file . " Section [" . a:ctx.section . "]: " . a:msg)
endfunction
" Add editorconfig file name, section and msg to error list
function! s:ParserError(ctx, msg)
  call add(b:editor_config_error, a:ctx.file . " Section [" . a:ctx.section . "]: " . a:msg)
endfunction

" ctx: Parsing context: filename, section
" kv: Key-Value-Pair: option name and value
function s:ProcessOption(ctx, kv)
  let key = a:kv[0]
  let value = a:kv[1]

  if value ==? 'unset'
    return [ key, '' ]
  endif

  let cfg = s:editor_config_config[a:kv[0]]
  if get(cfg, 'lower_case', v:false) == v:true
    let value = tolower(value)
  endif

  if has_key(cfg, 'value_process')
    let value = cfg.value_process(key, value)
  endif
  if type(value) == v:t_string
    if value ==# 'unset'
      return [ key, '' ]
    elseif value ==# '_IGNORE_'
      return []
    endif
  endif

  let Cmd=""
  if type(cfg.execute) == v:t_dict
    let lc_value = tolower(value)
    if has_key(cfg.execute, lc_value)
      let Cmd = cfg.execute[lc_value]
    else
      call s:ParserError(a:ctx, "Unsupported config value for " . key .": " . value . " (" . lc_value . ")")
      return []
    endif
  else
    let Cmd = cfg.execute
  endif

  if empty(Cmd)
    return [ key, '' ]
  else
    if type(Cmd) == v:t_func
      let Cmd = funcref(Cmd, [ value])
    else
      try
        " We insert the value in a string, escape backslashes
        let value = escape(value, '\')
        let Cmd = substitute(Cmd, '{v}', value, 'g')
        " TODO: Escape more characters in property value?
        let Cmd = substitute(Cmd, '{e}', escape(value, ' |\'), 'g')
      catch /E767:.*/
        "ignored: No format option
      endtry
    endif
    return [ key, Cmd ]
  endif

endfunction

" Creates a regex that matches all integer numbers between lower and upper
" Note: Numbers are swapped, if lower > upper
function s:GlobRange2Re(lower, upper)
  let start = min([a:lower, a:upper])
  let end = max([a:lower, a:upper])
  return '\(' . join(range(start, end), '\|') . '\)'
endfunction

" braces without or equal number of leading backslashes
let s:LEFT_BRACE = '\(\(\(\\\\\)*\)\@>\\\)\@<!{'
let s:RIGHT_BRACE = '\(\(\(\\\\\)*\)\@>\\\)\@<!}'
let s:NUM_RANG = '[-+]\?\d\+\.\.[-+]\?\d\+'

" count matches of regex in string
function s:countMatch(str, re)
    let cnt = 0
    let w = 0
    let i = match(a:str, a:re, w)
    while i >= 0
        let cnt += 1
        let w = i + 1
        let i = match(a:str, a:re, w)
    endwhile
    return cnt
endfunction

if has("win32") && !has("win32unix")
  let s:RE_FSEP='[\\/]'
  let s:RE_NOT_FSEP='[^\\/]'
else
  let s:RE_FSEP='/'
  let s:RE_NOT_FSEP='[^/]'
endif


" This function is a translation of a python function
" from https://github.com/editorconfig/editorconfig-core-py
function s:GlobToRegEx(pat,...)

  let length = strlen(a:pat)
  let brace_level = 0
  let in_brackets = v:false
  let re = ''
  let is_escaped = v:false
  let matching_braces = s:countMatch(a:pat, s:LEFT_BRACE) == s:countMatch(a:pat, s:RIGHT_BRACE)

  let idx = 0
  while idx < length
    let c = a:pat[idx]
    let idx += 1
    if c == '*'
      if a:pat[idx] == '*'
        let re .= '.*'
      else
        let re .= s:RE_NOT_FSEP . '*'
      endif
    elseif c == '?'
      let re .= '.'
    elseif c == '['
      if in_brackets
        let re .= '\['
      else
        let wlk = idx
        let has_slash = v:false
        while wlk < length && a:pat[wlk] != ']'
          if a:pat[wlk] == '/' && a:pat[wlk-1] != '\'
            let has_slash = v:true
          endif
          let wlk += 1
        endwhile
        if wlk == length
          let re .= '\['
        elseif has_slash
          " TODO: I think recursive is correct
          "let re .= '\[' . a:pat[idx:(wlk-1)] . '\]'
          let inner = s:GlobToRegEx(a:pat[idx:(wlk-1)], v:true)
          let re .= '\[' . inner . '\]'
          let idx = wlk + 1
        else
          if a:pat[idx] == '!' || a:pat[idx] == '^'
            let idx +=1
            let re .= '[^'
          else
            let re .= '['
          endif
          let in_brackets = v:true
        endif
      endif
    elseif c == ']'
      let re .= ']'
      let in_brackets = v:false
    elseif c == '{'
      let wlk = idx
      let has_comma = v:false
      while wlk < length && a:pat[wlk] != '}' || is_escaped
        if a:pat[wlk] == ',' && !is_escaped
          let has_comma = v:true
          break
        endif
        let is_escaped = a:pat[wlk] == '\' && !is_escaped
        let wlk += 1
      endwhile
      if !has_comma && wlk < length
        let num_range = matchstr(a:pat[idx:(wlk-1)], s:NUM_RANG)
        if !empty(num_range)
          let bounds = eval(substitute(num_range, '^\([-+]\?\d\+\)\.\.\([-+]\?\d\+\)$', "[ \\1, \\2 ]", ''))
          let re .= s:GlobRange2Re(bounds[0], bounds[1])
        else
          let inner = s:GlobToRegEx(a:pat[idx:(wlk-1)], v:true)
          let re .= '{' . inner . '}'
        endif
        let idx = wlk + 1
      elseif matching_braces
        let re .= '\%('
        let brace_level += 1
      else
        let re .= '{'
      endif
    elseif c == ','
      if brace_level > 0 && !is_escaped
        let re .= '\|'
      else
        let re .= ','
      endif
    elseif c == '}'
      if brace_level > 0 && !is_escaped
        let re .= '\)'
        let brace_level -= 1
      else
        let re .= '}'
      endif
    elseif c == '/'
      if a:pat[idx:(idx+2)] == '**/'
        let re .= s:RE_FSEP . '\(.*' . s:RE_FSEP . '\)\?'
        let idx += 3
      else
        let re .= s:RE_FSEP
        " '/'
      endif
    elseif c != '\'
      " TODO: Escape c here! Better way?
      let re .= escape(c, ']')
    endif

    if c == '\'
      if is_escaped
        let re .= '\\'
      endif
      let is_escaped = !is_escaped
    else
      let is_escaped = v:false
    endif
  endwhile

  if empty(a:000)
    if stridx(a:pat, '/') < 0
      let re = s:RE_FSEP . '\(.*' . s:RE_FSEP . '\)\?' . re
    elseif strpart(re, 0, strlen(s:RE_FSEP)) != s:RE_FSEP
      let re = s:RE_FSEP . re
    endif
    let re .= '$'
  endif

  try
    call match("", re)
    if get(g:, "editor_config_debug", 0) >= 3
      call editorconfig#Debug("Glob2RE: %s -> %s", a:pat, re)
    endif
  catch /.*/
    echoms "Exception: " v:exception
    echoerr "Invalid regex: " . a:pat . " -> " . re
  endtry

  return re
endfunction

" a not escaped # or ;
let s:LINE_COMMENT = '\(\(\(\\\\\)*\)\@>\\\)\@<![#;]'

" parse the .editorconfig file
function s:ParseFile(fn)
  let fqfn = fnamemodify(a:fn, ':p')

  let cfg = { 'root': 'false', 'fcfg': [] }

  let pattern = ''
  let fcfg = {}

  let fqdir = fnamemodify(a:fn, ':p:h')
  let fqdir_re = substitute(glob2regpat(fqdir), '^\^\|\$$', '', 'g')
  let cfg['.ec_file'] = fqfn

  " context for warning/error messages
  let ctx = { 'file': fqfn, 'section': '' }

  " read file, remove all comments and drop empty lines
  for ln in filter(map(readfile(a:fn), {i, v -> trim(substitute(v, '\(^[#;]\|\s\+' . s:LINE_COMMENT . '\).*$', '', ''))}), {i, v -> v != '' })
    if ln =~ '^\[.*\]$'
      " found a section ([glob-expr])
      if !empty(pattern)
        " save previous section
        call add(cfg.fcfg, [ pattern, fcfg ])
        let pattern = ''
        let fcfg = {}
      else
        " no previous section, so this are toplevel elements
        for [key, value] in items(fcfg)
          let cfg[key] = value
        endfor
      endif

      " translate glob to regex
      let glob = strpart(ln, 1, strlen(ln) -2)

      let pattern = fqdir_re . s:GlobToRegEx(glob)
      let fcfg['.ec_glob'] = glob

      let ctx.section = glob
      continue
    endif
    if ln =~ '^\w\+\s*[=:]\s*\S.*$'
      " a line with property and value
      let kv = eval(substitute(ln, '^\(\w\+\)\s*[=:]\s*\(\S.*\)$', "[ tolower('\\1'), '\\2' ]", ''))
      if empty(pattern)
        let cfg[kv[0]] = kv[1]
      else
        let fcfg[kv[0]] = kv[1]
      endif
    else
      call s:ParserError(ctx, "Can't parse line: " . ln)
    endif
  endfor
  if !empty(pattern)
    call add(cfg.fcfg, [ pattern, fcfg ])
  endif

  return cfg
endfunction

" Apply parsed settings to file (buffer)
function! s:ApplyEditorConfig(filename, ec_list)
  let cmds = {}
  " find properties that should be applied
  for ec in a:ec_list
    let fcfg = ec.fcfg
    for c in fcfg
        if get(g:, "editor_config_debug", 0) >= 3
          call editorconfig#Debug('match Filename: %s -> %s', a:filename, c[0])
        endif

      if match(a:filename, c[0]) >=0
        call editorconfig#Debug('Applying from %s [%s]', ec['.ec_file'], c[1]['.ec_glob'])
        if get(g:, "editor_config_debug", 0) >= 3
          call editorconfig#Debug('Properties: %s', string(c[1]))
        endif

        " context used for error/warning
        let ctx = { 'file': ec['.ec_file'], 'section': c[1]['.ec_glob'] }
        for [property, value] in items(c[1])
          if has_key(s:editor_config_config, property)
            " process the property & value to determine statement to execute
            " in Vim
            try
              let kv = s:ProcessOption(ctx, [ property, value ])
              if !empty(kv)
                let cmds[kv[0]] = { 'value': value, 'cmd': kv[1] }
              endif
            catch /^EditorConfig:.*$/
              let msg = matchstr(v:exception, '^EditorConfig:\s*\zs.*\ze$')
              call s:ParserError(ctx, msg)
            endtry
          else
            if property[0] != '.'
              call s:ParserWarning(ctx, "Unsupported option: " . property . " = " . value)
            endif
          endif
        endfor
      endif
    endfor
  endfor

  for [property, propInfo] in items(cmds)
    " ignore properties starting with dot, they are our extensions
    if property[0] == '.'
      continue
    endif

    let Cmd = propInfo.cmd

    " inform listeners
    for Listener in editorconfiglistener#get()
      try
        call Listener(property, propInfo.value)
      catch /.*/
        " hook threw exception -- unregister it
        echomsg "Deregistering hook " . string(Listener) ." after exception \"" . v:exception . "\""
        call editorconfiglistener#unregister(Listener)
      endtry
    endfor

    " execute the Vim statments (command otr function call)
    if type(Cmd) == v:t_func
      call Cmd()
    else
      if !empty(Cmd)
        try
          execute(Cmd)
          call editorconfig#Info(Cmd)
        catch /.*/
          call editorconfig#Warning(property .': ' . Cmd . " Failed with: " . v:exception)
        endtry
      endif
    endif
  endfor

  " Special handling for the dependencies between indent_size and tab_width.
  if &l:shiftwidth != 0 && !has_key(cmds, 'tab_width')
    " indent_size (=shiftwidth) is set, but tab_width is not set.
    " -> Set tab_width to indent_size
    " -> VIM: tabstop to shiftwidth
    call editorconfig#Debug("Adjusting tab_width to indent_size")
    let &l:tabstop = &l:shiftwidth
  elseif has_key(cmds, 'tab_width') && !has_key(cmds, 'indent_size')
    " tab_width is set, but indent_size is not
    " -> Set indent_size to tab_width
    " -> VIM: shiftwidth to 0, as it then defaults to tabstop
    let &l:shiftwidth = 0
  endif

endfunction

" Handle editor config for given filename and the given .editorconfig files.
function! editorconfig#HandleEditorConfig(filename, ec_files)

  " If global function EditorConfigPre exists, call it
  if exists("*EditorConfigPre")
    call EditorConfigPre()
  endif

  if !exists("b:editor_config")
    let b:editor_config = []
  endif
  let b:editor_config_warning = []
  let b:editor_config_error = []

  " parse the editorconfig files until "root = true" is found
  let ec_list = []
  for ecf in a:ec_files
    let ec = s:ParseFile(ecf)
    call insert(ec_list, ec, 0)
    if ec.root ==? 'true'
      break
    endif
  endfor

  " Apply settings to file
  call s:ApplyEditorConfig(a:filename, ec_list)

  " If global function EditorConfigPost exists, call it
  if exists("*EditorConfigPost")
    call EditorConfigPost()
  endif

  " if not quiet print a message if a error was found
  if ! exists('g:editor_config_quiet')
    if ! empty(b:editor_config_error) || ( exists('g:editor_config_picky') && ! empty(b:editor_config_warning) )
      echohl ErrorMsg
      echomsg "EditorConfig Warnings/Errors. Execute ':EditorConfigStatus' for details."
      echohl None
    endif
  endif

endfunction

" Editor config command interface
" Currently only supports 'status' to report - wel - status
" Note: Subcommand 'apply' is directly handled in plugin/editorconfig.vim
function! editorconfig#EditorConfigCmd(bang, subcmd)
  if a:subcmd == 'status'
    call s:EditorConfigStatus()
  else
    echohl ErrorMsg
    echomsg "Editorconfig: Unknown command '" . a:subcmd . "'"
    echohl None
  endif
endfunction

" print status of editor config for current buffer
function! s:EditorConfigStatus()
  if ! exists("b:editor_config")
    echohl ErrorMsg
    echo "No EditorConfig loaded."
    echohl None
    return
  endif

  echo "EditorConfig Info:"
  if ! empty(b:editor_config)
    for ln in b:editor_config
      echo "- " . ln
    endfor
  else
    echo "None"
  endif

  if exists("b:editor_config_warning") && !empty(b:editor_config_warning)
    echohl WarningMsg
    echo "EditorConfig Warnings:"
    for ln in b:editor_config_warning
      echo "- " . ln
    endfor
    echohl None
  endif

  if exists("b:editor_config_error") && !empty(b:editor_config_error)
    echohl ErrorMsg
    echo "EditorConfig Errors:"
    for ln in b:editor_config_error
      echo "- " . ln
    endfor
    echohl None
  endif
endfunction


