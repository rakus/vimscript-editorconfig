"
" FILE: editorconfig_g2re.vim
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
"
" a number range like '1..5' or '-5..+3'
let s:NUM_RANG = '[-+]\?\d\+\.\.[-+]\?\d\+'


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

function s:numRangeRegexParts(min, max, append) abort
  let parts = []
  if a:min == a:max
    call add(parts, string(a:min). a:append)
  elseif (a:min/10) == (a:max/10)
    call add(parts, strpart(a:min, 0, len(a:min)-1) . '[' . (a:min%10) . '-' . (a:max%10) . ']'. a:append)
  else
    let new_min = ((a:min/10)+1)*10
    let new_max = ((a:max/10))*10
    if(new_min != a:min)
      if (a:min%10) == 9
        call add(parts, string(a:min) . a:append)
      else
        call add(parts, strpart(a:min, 0, len(a:min)-1) . '[' . (a:min%10) . '-9]' . a:append)
      endif
    endif
    if new_min != new_max
      call extend(parts, s:numRangeRegexParts(new_min/10, (new_max/10)-1, '[0-9]' . a:append))
    endif
      if (a:max%10) == 0
        call add(parts, string(a:max) . a:append)
      else
        "call add(parts, strpart(a:max, 0, len(a:max)-1) .  '[0-' . (a:max%10) . ']' . a:append)
        call extend(parts, s:numRangeRegexParts(new_max/10, a:max/10, '[0-' . (a:max%10) . ']' . a:append))
      endif
  endif

  return parts
endfunction

function s:GlobRange2Re(lower, upper) abort

  let start = min([a:lower, a:upper])
  let end = max([a:lower, a:upper])
  let neg=''
  if start < 0
    let new_start = end < 0 ? -end : 0
    let new_end = start * -1
    let result = s:numRangeRegexParts(new_start, new_end, '')
    let neg =  '-' . join(result, '\|-')
    if end < 0
      return '\%(' . neg . '\)'
    else
      let neg .=  '\|'
    endif
    let start = 0
  endif
  let result = s:numRangeRegexParts(start, end, '')

  return '\%(' . neg . '+\?' . join(result, '\|+\?') . '\)'

endfunction

" Searches for a closing ']'  and returns its index.
" if no closing bracket is found or a '/' is found before the closing bracket,
" -1 is returned.
function s:getClosingBracketIndex(pat, idx) abort
  let len = len(a:pat)
  let wlk = a:idx
  while wlk < len && a:pat[wlk] != ']'
    if a:pat[wlk] == '/'
      return -1
    endif
    if a:pat[wlk] == '\'
      let wlk +=1
    endif
    let wlk +=1
  endwhile

  return wlk >= len? -1 : wlk
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
    let wlk = -1
  endif
  return [ wlk, has_comma ]
endfunction

" Unescapes the part of the character array.
function s:unescape(pat, start, end) abort
  let wlk = a:start
  let unesc = ''
  while wlk < a:end
    if a:pat[wlk] == '\'
      let wlk += 1
    endif
    let unesc .= a:pat[wlk]
    let wlk += 1
  endwhile
  return unesc
endfunction

function s:GlobToRegExInt(pat,type) abort

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
      else
        let re .= s:RE_NOT_FSEP . '*'
      endif
    elseif c == '?'
      let re .= '.'
    elseif c == '['
      if a:type == s:g2rInBrackets
        let re .= '\['
      else
        let wlk = s:getClosingBracketIndex(a:pat, idx)
        if wlk < 0
          let re .= '\['
        else
          if a:pat[idx] == '!' || a:pat[idx] == '^'
            let idx +=1
            let re .= '[^'
          else
            let re .= '['
          endif
          let re .= s:unescape(a:pat, idx, wlk)
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
            let num_range = matchstr(partStr, s:NUM_RANG)
            if !empty(num_range)
              let bounds = eval(substitute(num_range, '^\([-+]\?\d\+\)\.\.\([-+]\?\d\+\)$', "[ \\1, \\2 ]", ''))
              let re .= s:GlobRange2Re(bounds[0], bounds[1])
            else
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
      if a:type == s:g2rInBraces
        let re .= '\|'
      else
        let re .= ','
      endif
    elseif c == '/'
      if idx < (length-2) && a:pat[idx] == '*' && a:pat[idx+1] == '*' && a:pat[idx+2] == '/'
        let re .= s:RE_FSEP . '\(.*' . s:RE_FSEP . '\)\?'
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



