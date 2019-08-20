" editorconfig.vim: (global plugin) editorconfig support for Vim
" glob to regex translation editorconfig plugin, see ../plugin/editorconfig.vim
" Version:     0.1
" Last Change: 2019 Aug 20

"
" Provides editorconfig_g2re#GlobToRegEx(glob-pattern)
"
" This is a new from-scratch implementation to translate editorconfig glob
" expressions to Vim regular expressions.
" - handling of escaped chars
" - better detection of / in []
" - better handling of {}
" - resulting regex adjusted when win32 detected
" - check that resulting regex is valid
" - compacter RE for number ranges


let s:glob2re_cache = {}

let s:NUMBER_MODE="AS_IS"
"let s:NUMBER_MODE="ZEROS"
"let s:NUMBER_MODE="JUSTIFIED"

" To be deleted when NUMBER_MODE not needed anymore
function editorconfig_g2re#NumberMode()
  return s:NUMBER_MODE
endfunction

if has("win32") && !has("win32unix")
  let s:RE_FSEP='[\\/]'
  let s:RE_NOT_FSEP='[^\\/]'
else
  let s:RE_FSEP='/'
  let s:RE_NOT_FSEP='[^/]'
endif

let s:g2rNormal = 0
let s:g2rInBrackets = 1
let s:g2rInBraces = 2
lockvar s:g2rNormal s:g2rInBrackets s:g2rInBraces
"
" a number range like '1..5' or '-5..+3'
let s:NUM_RANGE = '[-+]\?\d\+\.\.[-+]\?\d\+'
lockvar s:NUM_RANGE

let s:CHARACTER_CLASS_SPECIAL = "^-]\\"
lockvar s:CHARACTER_CLASS_SPECIAL

function editorconfig_g2re#ClearCache()
  let s:glob2re_cache = {}
endfunction

function editorconfig_g2re#GlobToRegEx(pat) abort
  if has_key(s:glob2re_cache, a:pat)
    return s:glob2re_cache[a:pat]
  endif
  try
    let re = s:GlobToRegExInt(split(a:pat, '\zs'), s:g2rNormal)
  catch /.*/
    let errorMsg = "Error for " . a:pat . ": " . v:exception . " [" . v:throwpoint . "]"
    call editorconfig#Error(errorMsg)
    throw errorMsg
  endtry
  if stridx(a:pat, '/') < 0
      let re = s:RE_FSEP . '\(.*' . s:RE_FSEP . '\)\?' . re
  elseif strpart(re, 0, strlen(s:RE_FSEP)) != s:RE_FSEP
      let re = s:RE_FSEP . re
  endif
  let re .= '$'

  " test the generated regular expression
  try
    call match("", re)
    let  s:glob2re_cache[a:pat] = re
    call editorconfig#Debug("Glob2RE: %s -> %s", a:pat, re)
  catch /.*/
    call editorconfig#Debug("Invalid regex: %s -> %s Exception: %s", a:pat, re, v:exception)
    throw "Invalid Glob: Can't translate glob pattern: " . a:pat . " Exception: " . v:exception
  endtry
  return re
endfunction

function s:GlobToRegExInt(pat,state) abort
  let length = len(a:pat)
  let brace_level = 0
  let re = ''

  let idx = 0
  while idx < length
    let c = a:pat[idx]
    let idx +=1
    if c == '*'
      if idx < length && a:pat[idx] == '*'
        let re .= '.*'
        let idx +=1
      else
        let re .= s:RE_NOT_FSEP . '*'
      endif
    elseif c == '?'
      let re .= s:RE_NOT_FSEP
    elseif c == '['
      if a:state == s:g2rInBrackets
        let re .= '\['
      else
        let wlk = s:getClosingBracketIndex(a:pat, idx, a:state)
        if wlk < 0
          " not closed OR '/' found OR ',' found and state == s:g2rInBraces
          let re .= '\['
        else
          let re .= '['
          let re .= s:handleCharacterClass(a:pat, idx, wlk)
          let re .= ']'
          let idx = wlk + 1
        endif
      endif
    elseif c == '{'
        let wlk = idx

        " find closing } and check if ',' is in range
        let [wlk, has_comma] = s:getClosingBracesIndex(a:pat, idx)

        if wlk >= 0
          if !has_comma
            let partStr = join(a:pat[idx:(wlk-1)], '')
            let num_range = matchstr(partStr, s:NUM_RANGE)
            if !empty(num_range)
              let bounds = eval(substitute(num_range, '^\([-+]\?\d\+\)\.\.\([-+]\?\d\+\)$', "[ '\\1', '\\2' ]", ''))
              let re .= s:GlobRange2Re(bounds[0], bounds[1])
            else
              call editorconfig#Warning("Brace without comma. Escape it, to silence this warning: " . join(a:pat, ''))
              let inner = s:GlobToRegExInt(a:pat[idx:(wlk-1)], s:g2rNormal)
              let re .= '{' . inner . '}'
            endif
            let idx = wlk + 1
          else
            let inner = s:GlobToRegExInt(a:pat[idx:(wlk-1)], s:g2rInBraces)
            let re .= '\%(' . inner . '\)'
            let idx = wlk + 1
          endif
        else
          let re .= '{'
        endif
    elseif c == ','
      if a:state == s:g2rInBraces
        let re .= '\|'
      else
        let re .= ','
      endif
    elseif c == '/'
      if idx < (length-2) && a:pat[idx] == '*' && a:pat[idx+1] == '*' && a:pat[idx+2] == '/'
        let re .= s:RE_FSEP . '\%(.*' . s:RE_FSEP . '\)\?'
        let idx += 3
      else
        let re .= s:RE_FSEP
        " '/'
      endif
    elseif c == '\'
      if idx < length
        let c = a:pat[idx]
      endif
      let re .= escape(c, '^$[]*.\\')
      let idx +=1
    elseif c != '\'
      " TODO: Escape c here! Better way?
      let re .= escape(c, '^$[]*.')
    endif
  endwhile
  return re
endfunction

" Searches for a closing ']'  and returns its index.
" if no closing bracket is found or a '/' is found before the closing bracket
" -1 is returned. Also returns -1 if a unescaped ',' is found and state ==
"  s:g2rInBraces.
function s:getClosingBracketIndex(pat, idx, state) abort
  let len = len(a:pat)
  let wlk = a:idx
  while wlk < len && a:pat[wlk] != ']'
    if a:pat[wlk] == '/'
      call editorconfig#Warning("Slash found while searching for closing square bracket. Remove slash or escape square bracket, to silence this warning: " . join(a:pat, ''))
      return -1
    elseif a:pat[wlk] == ',' && a:state == s:g2rInBraces
      return -1
    endif
    if a:pat[wlk] == '\'
      let wlk +=1
    endif
    let wlk +=1
  endwhile

  if wlk >= len
    call editorconfig#Warning("Unclosed square bracket found. Escape it, to silence this warning: " . join(a:pat, ''))
    return -1
  else
    return wlk
  endif
endfunction

" Searches for a closing '}' and returns a array with its index and whether a
" comma was found.
" This also handles inner {}.
" TODO: Do we need to handle [] here?
function s:getClosingBracesIndex(pat, idx) abort
  let len = len(a:pat)
  let wlk = a:idx
  let has_comma = v:false
  while wlk < len && a:pat[wlk] != '}'
    if a:pat[wlk] == ','
      let has_comma = v:true
    elseif a:pat[wlk] == '{'
      let [iwlk, icomma ] = s:getClosingBracesIndex(a:pat, wlk+1)
      if iwlk >= 0
        let wlk = iwlk
      elseif icomma
        let has_comma = v:true
      endif
    endif
    if a:pat[wlk] == '\'
      let wlk +=1
    endif
    let wlk +=1
  endwhile

  if wlk >= len
    call editorconfig#Warning("Unclosed brace found. Escape it, to silence this warning: " . join(a:pat, ''))
    let wlk = -1
  endif
  return [ wlk, has_comma ]
endfunction

" Unescapes the part of the character array.
function s:handleCharacterClass(pat, start, end) abort
  let wlk = a:start
  let result = ''

  if a:pat[wlk] == '!' || a:pat[wlk] == '^'
    let wlk += 1
    let result .= '^'
  endif

  while wlk < a:end
    if a:pat[wlk] == '\'
      if (wlk + 1) < a:end
        let wlk += 1
        if stridx(s:CHARACTER_CLASS_SPECIAL, a:pat[wlk]) >= 0
          let result .= '\'
        endif
        let result .= a:pat[wlk]
      else
        let result .= '\\'
      endif
    elseif a:pat[wlk] == '-'
      let result .= '-'
    else
      if stridx(s:CHARACTER_CLASS_SPECIAL, a:pat[wlk]) >= 0
        let result .= '\'
      endif
      let result .= a:pat[wlk]
    endif
    let wlk += 1
  endwhile
  return result
endfunction


" Create regular expression to match the number range lower to upper
function s:GlobRange2Re(lower, upper) abort
  "Special Handling leading zeros.
  let width = -1
  " If bash-like justified numbers are wanted, enable the following
  if s:NUMBER_MODE == "JUSTIFIED"
    if match(a:lower, '^[-+]\?0\d') == 0 || match(a:upper, '^[-+]\?0\d') == 0
      let width = max([ strlen(substitute(a:lower, "+", "", "")), strlen(substitute(a:upper, "+", "", "")) ] )
    endif
  endif

  let low_num = str2nr(a:lower, 10)
  let up_num = str2nr(a:upper, 10)

  let start = min([low_num, up_num])
  let end = max([low_num, up_num])
  let neg=''
  if start < 0
    if s:NUMBER_MODE != "JUSTIFIED"
      let new_start = end < 0 ? -end : 0
    else
      let new_start = end < 0 ? -end : 1
    endif
    let new_end = start * -1
    let neg = s:num_re(width-1, new_start, new_end, '')
    if s:NUMBER_MODE == "ZEROS"
      let neg =  '-0*\%(' . neg . '\)'
    else
      let neg =  '-\%(' . neg . '\)'
    endif
    if end < 0
      return '\%(' . neg . '\)'
    else
      let neg .=  '\|'
    endif
    let start = 0
  endif
  let pos = s:num_re(width, start, end, '')

  if s:NUMBER_MODE == "JUSTIFIED"
    return '\%(' . neg . pos . '\)'
  elseif s:NUMBER_MODE == "ZEROS"
    return '\%(' . neg . '+\?0*\%(' . pos . '\)\)'
  else
    return '\%(' . neg . '+\?\%(' . pos . '\)\)'
  endif

endfunction


function s:num_re(a_width, min, max, suffix)
  let width    = a:a_width > 0 ? a:a_width : 0
  let width10s = a:a_width > 0 ? a:a_width - 1 : 0

  if a:min == a:max
      return printf("%0*d%s", width, a:min, a:suffix)
  endif
  if a:min/10 == a:max/10
    if a:min >= 10 || width10s > 0
      return printf("%0*d[%d-%d]%s", width10s, a:min/10, a:min%10, a:max%10, a:suffix)
    else
      return printf("[%d-%d]%s", a:min%10, a:max%10, a:suffix)
    endif
  endif

  let re = ""

  " Short cut for justified 0-99*
  if a:min == 0 && width >= s:digits(a:max) && s:digits(a:max) < s:digits(a:max+1)
    while width > s:digits(a:max)
      let re .= '0'
      let width -= 1
    endwhile
    for i in range(width)
      let re .= "[0-9]"
    endfor
    return re
  endif

  " if min is not divisible by 10, create re to match the gap to the next
  " number divisable by 10
  if a:min == 0 || a:min%10 != 0
    let new_min = (a:min/10+1)*10
    let re .= s:num_re(width, a:min, new_min-1, a:suffix)
  else
    let new_min = a:min
  endif

  " move new_min forward to have the same number of digits like max
  " create the needed re
  let new_suffix=a:suffix . "[0-9]"
  let div = 1
  while(s:digits(new_min) < s:digits(a:max))
    let div = div * 10
    let next_min = float2nr(pow(10, s:digits(new_min)))
    if re != ""
      let re .= "\\|"
    endif
    let re .= s:num_re(width-s:digits(new_min)+1, new_min/div, (next_min-1)/div, new_suffix)
    let new_min = next_min
    let new_suffix .= "[0-9]"
  endwhile

  " new_min now has the same number of digits like max
  let div = float2nr(pow(10, s:digits(new_min)-1))
  while div > 1
    let new_max = (a:max / div)*div
    if (new_max + div-1) == a:max
      " special handling for numbers ending with '9'
      " We can handle it in this loop.
      let new_max = a:max
    endif
    if new_min != new_max
      let x=div
      let new_suffix=""
      while x > 1
        let new_suffix .= "[0-9]"
        let x = x/10
      endwhile
      if re != ""
        let re .= "\\|"
      endif
      let re .= s:num_re(width-s:digits(new_min)+1, new_min/div, (new_max-1)/div, new_suffix)
    endif
    let new_min = new_max
    let div = div/10
  endwhile

  if new_min < a:max
    if re != ""
      let re .= "\\|"
    endif
    let re .= s:num_re(width10s, new_min/10, (a:max)/10, printf("[0-%d]", a:max%10))
  elseif new_min%10 != 9
    if re != ""
      let re .= "\\|"
    endif
    let re .= printf("%0*d", width, a:max)
    " else: The number ended with '9'/'99'/'999'... and was handled in the loop above
  endif

  return re
endfunction

function s:digits(num)
  if a:num < 10
    return 1
  elseif a:num < 10
    return 1
  elseif a:num < 100
    return 2
  elseif a:num < 1000
    return 3
  else
    let n = a:num/1000
    let d=3
    while n > 0
      let n = n/10
      let d += 1
    endwhile
    return d
  endif
endfunction


