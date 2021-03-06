" editorconfig.vim: (global plugin) editorconfig support for Vim
" autoload script of editorconfig plugin, see ../plugin/editorconfig.vim
" Version:     0.1
" Last Change: 2019 Aug 23

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

" Function to trim trailing whitespaces before saving the file.
" Called via autocmd, see SetTrimTrailingWhitespaces below.
function! s:TrimTrailingWhiteSpace() abort
  let save_pos = winsaveview()
  try
    keeppattern %s/\s\+$//e
  finally
    call winrestview(save_pos)
  endtry
endfunction

" checks hat the value is a integer > 0
" throws exception if not
function! s:PositiveInteger(name, value) abort
  if a:value =~ '^\d\+$'
    let int = str2nr(a:value)
    if int == 0
      throw "EditorConfig: " . a:name . ": Must not be 0"
    endif
    return int
  else
      throw "EditorConfig: Invalid " . a:name . ": \"" . a:value . "\""
  endif
endfunction

function s:SetIndentStyle(value) abort
  if a:value ==? "tab"
    setlocal noexpandtab
  elseif a:value ==? "space"
    setlocal expandtab
  else
    throw "EditorConfig: Invalid value for indent_style: " . value)
  endif
endfunction

function s:SetIndentSize(value) abort
  if 'tab' == a:value
    let indent = 0
  else
    let indent = s:PositiveInteger("indent_size", a:value)
  endif
  let &l:shiftwidth=indent
  let &l:softtabstop=indent
endfunction

function s:SetTabWidth(value) abort
  let &l:tabstop = s:PositiveInteger("tab_width", a:value)
endfunction

function s:SetEndOfLine(value) abort
  if a:value ==? "lf"
    setlocal fileformat=unix
  elseif a:value ==? 'cr'
    setlocal fileformat=mac
  elseif a:value ==? 'crlf'
    setlocal fileformat=dos
  else
    throw "EditorConfig: Invalid value for end_of_line: " . value)
  endif
endfunction

function s:SetTrimTrailingWhitespaces(value) abort
  if a:value ==? "true"
    augroup EditorConfigTrim
      autocmd! * <buffer>
      autocmd BufWritePre <buffer> :call s:TrimTrailingWhiteSpace()
    augroup END
  elseif a:value ==? 'false'
    augroup EditorConfigTrim
      autocmd! * <buffer>
    augroup END
  else
    throw "EditorConfig: Invalid value for trim_trailing_whitespace: " . value)
  endif
endfunction

function s:SetFinalNewline(value) abort
  if a:value ==? "true"
      setlocal fixendofline
  elseif a:value ==? 'false'
      setlocal nofixendofline
  else
    throw "EditorConfig: Invalid value for insert_final_newline: " . value)
  endif
endfunction

function s:SetFileEncoding(value) abort
  if index(s:enc_names, a:value) == -1 && empty(map(s:enc_re, {i,v -> match(a:value, v) == 0}))
    throw "EditorConfig: Unsupported encoding: " . a:value
  endif

  let fenc = a:value
  if fenc == 'utf-8-bom'
    let fenc = 'utf-8'
  endif
  if fenc != &l:fileencoding
    let org_fenc = empty(&l:fileencoding)? 'unset' : &l:fileencoding
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
  endif

  " TODO: Is this the only case to set a bom?
  if a:value =~ '.*-bom$'
    setlocal bomb
    "call editorconfig#Info("Setting byte-order-mark")
  endif
endfunction

let s:MAX_LINE_COLOR_GROUP = "EditorConfigMaxLineLen"
function s:SetMaxLineLength(value) abort

  if hlexists(s:MAX_LINE_COLOR_GROUP) != 0
    for m in getmatches()
      if m.group == s:MAX_LINE_COLOR_GROUP
        call matchdelete(m.id)
      endif
    endfor
  endif

  if a:value == 'off'
    " TODO: Or use 0?
    let maxLen =  &l:textwidth
  else
    let maxLen = s:PositiveInteger('max_line_length', a:value)
  endif
  let &l:textwidth = maxLen

  let cfg = get(g:, "editorconfig_max_line_length_visual", "none")

  if cfg == "exceed"
    if hlexists(s:MAX_LINE_COLOR_GROUP) == 0
      execute "highlight link " . s:MAX_LINE_COLOR_GROUP . " ColorColumn"
    endif

    call matchadd(s:MAX_LINE_COLOR_GROUP, '\%>' . maxLen . 'v.\+', 100)
  elseif cfg == "ruler"
    setlocal colorcolumn=+1
  elseif cfg == "none"
    " do nothing
  else
    call editorconfig#Warning("Invalid value for g:editorconfig_max_line_length_visual ignored: " . cfg)
    " do nothing
  endif

endfunction

function s:SetSpellLang(value) abort
  let &l:spelllang=a:value
endfunction

function s:SetSpell(value) abort
  if a:value ==? "true"
      setlocal spell
  elseif a:value ==? 'false'
      setlocal nospell
  else
    throw "EditorConfig: Invalid value for spell_check: " . value)
  endif
endfunction

function s:NoOp() abort
endfunction

" dictionary of supported properties
" see :help editorconfig-extending for details
let s:editorconfig_config_default = {
      \ 'indent_style':             funcref("s:SetIndentStyle"),
      \ 'indent_size':              funcref("s:SetIndentSize"),
      \ 'tab_width':                funcref("s:SetTabWidth"),
      \ 'end_of_line':              funcref("s:SetEndOfLine"),
      \ 'trim_trailing_whitespace': funcref("s:SetTrimTrailingWhitespaces"),
      \ 'insert_final_newline':     funcref("s:SetFinalNewline"),
      \ 'charset':                  funcref("s:SetFileEncoding"),
      \ 'max_line_length':          funcref("s:SetMaxLineLength"),
      \ 'spell_lang':               funcref("s:SetSpellLang"),
      \ 'spell_check':              funcref("s:SetSpell")
      \}

let s:editorconfig_config = s:editorconfig_config_default

if exists('g:editorconfig_config')
  call extend(s:editorconfig_config, g:editorconfig_config)
endif

" Add msg to info list
function! editorconfig#Info(msg) abort
  call add(b:editorconfig_msgs, a:msg)
endfunction
" Add msg to warning list
function! editorconfig#Warning(msg) abort
  let b:editorconfig_status = get(b:, "editorconfig_status", "WARNING")
  call add(b:editorconfig_msgs, "WARNING: " . a:msg)
endfunction
" Add msg to warning list
function! editorconfig#Error(msg) abort
  let b:editorconfig_error = v:true
  let b:editorconfig_status = "ERROR"
  call add(b:editorconfig_msgs, "ERROR: " . a:msg)
endfunction
" Add msg to info list, if debug enabled
function! editorconfig#Debug(level, msg, ...) abort
  if get(g:, 'editorconfig_debug', 0) >= a:level
    " Debug might be called before buffer local vars are created.
    if !exists("b:editorconfig_msgs")
      let b:editorconfig_msgs = []
    endif
    if a:level > 1
      let prefix = "DEBUG-" . a:level
    else
      let prefix = "DEBUG"
    endif
    call add(b:editorconfig_msgs, prefix . ": " . call('printf', [a:msg] +  a:000))
  endif
endfunction

" Add editorconfig file name, section and msg to warning list
function! s:ParserWarning(ctx, msg) abort
  let b:editorconfig_status = get(b:, "editorconfig_status", "WARNING")
  call add(b:editorconfig_msgs, "WARNING: " . a:ctx.file . " Section [" . a:ctx.section . "]: " . a:msg)
endfunction
" Add editorconfig file name, section and msg to error list
function! s:ParserError(ctx, msg) abort
  let b:editorconfig_status = "ERROR"
  call add(b:editorconfig_msgs, "ERROR: " . a:ctx.file . " Section [" . a:ctx.section . "]: " . a:msg)
endfunction

" ctx: Parsing context: filename, section
" kv: Key-Value-Pair: option name and value
function s:ProcessOption(ctx, kv) abort
  let key = a:kv[0]
  let value = a:kv[1]

  if value ==? 'unset'
    return [ key, funcref("s:NoOp") ]
  endif

  let l:Cmd = s:editorconfig_config[a:kv[0]]

  if type(l:Cmd) == v:t_func
    let l:Cmd = funcref(l:Cmd, [ value])
    return [ key, l:Cmd ]
  else
    return [ key, funcref("s:NoOp") ]
  endif
endfunction

" a not escaped # or ;
let s:LINE_COMMENT = '\(\(\(\\\\\)*\)\@>\\\)\@<![#;]'

" parse the .editorconfig file
function s:ParseFile(fn) abort

  let INVALID_PATTERN = '||__INVALID__||'

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
        if pattern !=# INVALID_PATTERN
          " save previous section
          call add(cfg.fcfg, [ pattern, fcfg ])
        endif
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
      let ctx.section = glob

      if !empty(glob)
        try
          let pattern = fqdir_re . editorconfig_g2re#GlobToRegEx(glob)
        catch /Invalid Glob:.*/
          call s:ParserError(v:exception)
          call s:ParserWarning(ctx, "Ignoring section with invalid glob")
          let pattern = INVALID_PATTERN
        endtry
      else
        call s:ParserWarning(ctx, "Ignoring section with empty glob")
        let pattern = INVALID_PATTERN
      endif
      let fcfg['.ec_glob'] = glob

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
    if pattern != INVALID_PATTERN
      call add(cfg.fcfg, [ pattern, fcfg ])
    endif
  else
    " no previous section, so this are toplevel elements
    for [key, value] in items(fcfg)
      let cfg[key] = value
    endfor
  endif

  return cfg
endfunction

" Apply parsed settings to file (buffer)
function! s:ApplyEditorConfig(filename, ec_list) abort
  let cmds = {}
  " find properties that should be applied
  for ec in a:ec_list
    let fcfg = ec.fcfg
    for c in fcfg
      call editorconfig#Debug(2, 'match Filename: %s -> %s', a:filename, c[0])

      if match(a:filename, c[0]) >=0
        call editorconfig#Debug(1, 'Applying from %s [%s]', ec['.ec_file'], c[1]['.ec_glob'])
        call editorconfig#Debug(2, 'Properties: %s', string(c[1]))

        " context used for error/warning
        let ctx = { 'file': ec['.ec_file'], 'section': c[1]['.ec_glob'] }
        for [property, value] in items(c[1])
          if has_key(s:editorconfig_config, property)
            " process the property & value to determine statement to execute
            " in Vim
            try
              let kv = s:ProcessOption(ctx, [ property, value ])
              if !empty(kv)
                let cmds[kv[0]] = { 'value': value, 'cmd': kv[1], 'ctx': ctx }
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

    let l:Cmd = propInfo.cmd

    " inform listeners
    for l:Listener in editorconfiglistener#get()
      try
        call l:Listener(property, propInfo.value)
      catch /.*/
        " hook threw exception -- unregister it
        echomsg "Deregistering hook " . string(Listener) ." after exception \"" . v:exception . "\""
        call editorconfiglistener#unregister(Listener)
      endtry
    endfor

    " execute the Vim statments (command or function call)
    try
      call l:Cmd()
      call editorconfig#Info("Set " . property .': ' . propInfo.value)
    catch /^EditorConfig:.*$/
      let msg = matchstr(v:exception, '^EditorConfig:\s*\zs.*\ze$')
      call s:ParserError(propInfo.ctx, msg)
    catch /.*/
      call editorconfig#Warning(property .': Calling ' . string(l:Cmd) . " failed with: " . v:exception)
    endtry
  endfor

  " Special handling for the dependencies between indent_size and tab_width.
  if &l:shiftwidth != 0 && !has_key(cmds, 'tab_width')
    " indent_size (=shiftwidth) is set, but tab_width is not set.
    " -> Set tab_width to indent_size
    " -> VIM: tabstop to shiftwidth
    call editorconfig#Debug(1, "Adjusting tab_width to indent_size")
    let &l:tabstop = &l:shiftwidth
  elseif has_key(cmds, 'tab_width') && !has_key(cmds, 'indent_size')
    " tab_width is set, but indent_size is not
    " -> Set indent_size to tab_width
    " -> VIM: shiftwidth to 0, as it then defaults to tabstop
    let &l:shiftwidth = 0
  endif

endfunction

" Handle editor config for given filename and the given .editorconfig files.
function! editorconfig#HandleEditorConfig(filename, ec_files) abort

  " If global function EditorConfigPre exists, call it
  if exists("*EditorConfigPre")
    call EditorConfigPre()
  endif

  if !exists("b:editorconfig_msgs")
    let b:editorconfig_msgs = []
  endif

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
  if get(g:, "editorconfig_verbose", 0) >= 0
    let status = get(b:, "editorconfig_status", "")
    if status == "ERROR" || ( get(g:, "editorconfig_verbose", 0) >= 1 &&  status == "WARNING" )
      echohl ErrorMsg
      echomsg "EditorConfig Warnings/Errors. Execute ':EditorConfigStatus' for details."
      echohl None
    endif
  endif

endfunction

" print status of editor config for current buffer
function! editorconfig#EditorConfigStatus() abort
  if ! exists("b:editorconfig_msgs")
    echohl ErrorMsg
    echo "No EditorConfig loaded."
    echohl None
    return
  endif

  echo "EditorConfig Info:"
  if ! empty(b:editorconfig_msgs)
    for ln in b:editorconfig_msgs
      if ln =~ 'WARNING: .*'
        echohl WarningMsg
      elseif ln =~ 'ERROR: .*'
        echohl ErrorMsg
      endif
      echo "- " . ln
      echohl None
    endfor
  else
    echo "None"
  endif

endfunction


