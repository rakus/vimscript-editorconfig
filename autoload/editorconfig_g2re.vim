" editorconfig.vim: (global plugin) editorconfig support for Vim
" glob to regex translation editorconfig plugin, see ../plugin/editorconfig.vim
" Version:     0.1
" Last Change: 2019-05-06T07:27:16+0200

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
lockvar s:g2rNormal s:g2rInBrackets s:g2rInBraces
"
" a number range like '1..5' or '-5..+3'
let s:NUM_RANGE = '[-+]\?\d\+\.\.[-+]\?\d\+'
lockvar s:NUM_RANGE

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

function s:numRangeRegexParts(digits, min, max, append) abort
  "echo printf('numRangeRegexParts(%d, %d, %d, %s)', a:digits, a:min, a:max, a:append)
  let parts = []
  let width = a:digits <= 0 ? 0 : a:digits
  let width10s =  width > 0 ? width-1 : 0

  if a:min == a:max
    call add(parts, printf("%0*d%s", width, a:min, a:append))
    "echo "Added1: " . parts[-1]
  elseif (a:min/10) == (a:max/10)
    if a:min > 10
      call add(parts, printf("%0*d[%d-%d]%s", width10s, a:min/10, a:min%10, a:max%10, a:append))
    else
      call add(parts, printf("%[%d-%d]%s", a:min%10, a:max%10, a:append))
    endif
    "echo "Added2: " . parts[-1]
  else
    let new_min = ((a:min/10)+1)*10
    let new_max = ((a:max/10))*10
    if(new_min != a:min)
      if (a:min%10) == 9
        call add(parts, printf("%0*d%s", width, a:min, a:append))
        "echo "Added3: " . parts[-1]
      else
        if width > 0 || a:min >= 10
          call add(parts, printf("%0*d[%d-9]%s", width10s, a:min/10, a:min%10, a:append))
        else
          call add(parts, '[' . (a:min%10) . '-9]' . a:append)
        endif
        "echo "Added4: " . parts[-1]
      endif
    endif
    if new_min != new_max
      call extend(parts, s:numRangeRegexParts(a:digits-1, new_min/10, (new_max/10)-1, '\d' . a:append))
    endif
    if (a:max%10) == 0
      call add(parts, printf("%0*d%s", width, a:max, a:append))
      "echo "Added5: " . parts[-1]
    else
      call extend(parts, s:numRangeRegexParts(a:digits-1, new_max/10, a:max/10, '[0-' . (a:max%10) . ']' . a:append))
    endif
  endif

  return parts
endfunction

" external callable for testing
function editorconfig_g2re#GlobRange2Re(lower, upper) abort
  "echo printf("editorconfig_g2re#GlobRange2Re(%s, %s)", a:lower, a:upper)

  let digits = -1
  "Special Handling leading zeros. Disabled for now ...
  if match(a:lower, '^[-+]\?0\d') == 0 || match(a:upper, '^[-+]\?0\d') == 0
    let digits = max([ strlen(substitute(a:lower, "[+]", "", "")), strlen(substitute(a:upper, "[+]", "", "")) ] )
  else
    let digits = -1
  endif

  let low_num = str2nr(a:lower, 10)
  let up_num = str2nr(a:upper, 10)

  let start = min([low_num, up_num])
  let end = max([low_num, up_num])

  if start == end
    return (strlen(a:lower) > strlen(a:upper) ? a:lower : a:upper)
  endif

  let neg=''
  if start < 0
    let new_start = end < 0 ? -end : 1
    let new_end = start * -1
    let neg_digits = digits
    if(end >= 0)
      let neg_digits -= 1
    endif

    let result = s:numRangeRegexParts(neg_digits, new_start, new_end, '')
    let neg =  '-' . join(result, '\|-')
    if end < 0
      return '\%(' . neg . '\)'
    else
      let neg .=  '\|'
    endif
    let start = 0
  endif
  let result = s:numRangeRegexParts(digits, start, end, '')

  return '\%(' . neg .  join(result, '\|') . '\)'

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
      return -1
    elseif a:pat[wlk] == ',' && a:state == s:g2rInBraces
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
    elseif a:pat[wlk] == '{'
        let iwlk = s:getClosingBracketIndex(a:pat, idx)
        if iwlk >= 0
          let wlk = iwlk
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
      else
        let re .= s:RE_NOT_FSEP . '*'
      endif
    elseif c == '?'
      let re .= '.'
    elseif c == '['
      if a:state == s:g2rInBrackets
        let re .= '\['
      else
        let wlk = s:getClosingBracketIndex(a:pat, idx, a:state)
        if wlk < 0
          " not closed OR '/' found OR ',' found and state == s:g2rInBraces
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
            let num_range = matchstr(partStr, s:NUM_RANGE)
            if !empty(num_range)
              let bounds = eval(substitute(num_range, '^\([-+]\?\d\+\)\.\.\([-+]\?\d\+\)$', "[ '\\1', '\\2' ]", ''))
              let re .= editorconfig_g2re#GlobRange2Re(bounds[0], bounds[1])
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
      if a:state == s:g2rInBraces
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



