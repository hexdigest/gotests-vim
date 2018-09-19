" Binary installation for go-unit is copied from vim-go plugin
" https://github.com/fatih/vim-go
" https://github.com/fatih/vim-go/blob/master/plugin/go.vim
"
" https://github.com/fatih/vim-go/blob/master/LICENSE
" Copyright (c) 2015, Fatih Arslan
" All rights reserved.


"""""""""""""""""""""""""""""""""""""""
" Install binaries
"
" Run a shell command.
"
" these packages are used by gounit-vim and can be automatically installed if
" needed by the user with GoUnitInstallBinaries
let s:packages = {
  \ 'gounit':        ['github.com/hexdigest/gounit/cmd/gounit'],
  \ 'motion':        ['github.com/fatih/motion'],
\ }

" It will temporary set the shell to /bin/sh for Unix-like systems if possible,
" so that we always use a standard POSIX-compatible Bourne shell (and not e.g.
" csh, fish, etc.) See #988 and #1276.
function! s:system(cmd, ...) abort
  " Preserve original shell and shellredir values
  let l:shell = &shell
  let l:shellredir = &shellredir

  try
    return call('system', [a:cmd] + a:000)
  finally
    " Restore original values
    let &shell = l:shell
    let &shellredir = l:shellredir
  endtry
endfunction

function! s:exec(cmd, ...) abort
  let l:bin = a:cmd[0]
  let l:cmd = s:ShellJoin([l:bin] + a:cmd[1:])

  let l:out = call('s:system', [l:cmd] + a:000)
  return [l:out, s:ShellError()]
endfunction

function! s:ShellError() abort
  return v:shell_error
endfunction

" Shelljoin returns a shell-safe string representation of arglist. The
" {special} argument of shellescape() may optionally be passed.
function! s:ShellJoin(arglist, ...) abort
  try
    let l:ssl_save = &shellslash
    set noshellslash
    if a:0
      return join(map(copy(a:arglist), 'shellescape(v:val, ' . a:1 . ')'), ' ')
    endif

    return join(map(copy(a:arglist), 'shellescape(v:val)'), ' ')
  finally
    let &shellslash = ssl_save
  endtry
endfunction

" Exec runs a shell command cmd, which must be a list, one argument per item.
" Every list entry will be automatically shell-escaped
" Every other argument is passed to stdin.
function! s:ExecCmd(cmd, ...) abort
  if len(a:cmd) == 0
    echo "ExecCmd() called with empty a:cmd")
    return ['', 1]
  endif

  let l:bin = a:cmd[0]

  " Finally execute the command using the full, resolved path. Do not pass the
  " unmodified command as the correct program might not exist in $PATH.
  return call('s:exec', [[l:bin] + a:cmd[1:]] + a:000)
endfunction

" CheckBinaries checks if the necessary binaries to install the Go tool
" commands are available.
function! s:CheckBinaries()
  if !executable('go')
    echohl Error | echomsg "go-unit: go executable not found." | echohl None
    return -1
  endif

  if !executable('git')
    echohl Error | echomsg "go-unit: git executable not found." | echohl None
    return -1
  endif
endfunction

" Default returns the default GOPATH. If GOPATH is not set, it uses the
" default GOPATH set starting with Go 1.8. This GOPATH can be retrieved via
" 'go env GOPATH'
function! s:DefaultPath() abort
  if $GOPATH == ""
    " use default GOPATH via go env
    return s:UtilEnv("gopath")
  endif

  return $GOPATH
endfunction

" env returns the go environment variable for the given key. Where key can be
" GOARCH, GOOS, GOROOT, etc... It caches the result and returns the cached
" version.
function! s:UtilEnv(key) abort
  let l:key = tolower(a:key)
  if has_key(s:env_cache, l:key)
    return s:env_cache[l:key]
  endif

  if executable('go')
    let l:var = call('GoPath', [])
  else
    let l:var = eval("$".toupper(a:key))
  endif

  let s:env_cache[l:key] = l:var
  return l:var
endfunction

" gopath returns 'go env GOPATH'. This is an internal function and shouldn't
" be used. Instead use 'go#util#env("gopath")'
function! s:GoPath() abort
  return substitute(s:exec(['go', 'env', 'GOPATH'])[0], '\n', '', 'g')
endfunction

" main download function for Go-unit
function! s:GoUnitInstall()
  let l:cmd = ['go', 'get', '-v']
  let final_msg = ""

  if !executable('gounit') || !executable('motion')
    " check if we can download and install gounit with go and git
    let l:err = s:CheckBinaries()
    if l:err != 0
      return
    endif
    if s:DefaultPath() == ""
      echohl Error
      echomsg "gounit-vim: $GOPATH is not set and 'go env GOPATH' returns empty"
      echohl None
      return
    endif
    let l:final_msg = "binaries"
  else 
    " otherwise we use this to update plugins
    let l:cmd += ['-u']
    let final_msg = "updates"
    echomsg "gounit-vim: updating gounit tools."
  endif

  let l:go_bin_path = s:DefaultPath()
  " let l:pluginPath = 'github.com/hexdigest/gounit/cmd/gounit'


  " Filter packages from arguments (if any).
  let l:packages = {}
  if a:0 > 0
    for l:bin in a:000
      let l:pkg = get(s:packages, l:bin, [])
      if len(l:pkg) == 0
        echoerr 'unknown binary: ' . l:bin
        return
      endif
      let l:packages[l:bin] = l:pkg
    endfor
  else
    let l:packages = s:packages
  endif

  " when shellslash is set on MS-* systems, shellescape puts single quotes
  " around the output string. cmd on Windows does not handle single quotes
  " correctly. Unsetting shellslash forces shellescape to use double quotes
  " instead.
  let l:resetshellslash = 0
  if has('win32') && &shellslash
    let l:resetshellslash = 1
    set noshellslash
  endif

  for [binary, pkg] in items(l:packages)
    let l:importPath = pkg[0]

    let l:run_cmd = copy(l:cmd)
    if len(l:pkg) > 1 && get(l:pkg[1], l:platform, '') isnot ''
      let l:run_cmd += get(l:pkg[1], l:platform, '')
    endif

    let binname = "go_" . binary . "_bin"

    let bin = binary
    if exists("g:{binname}")
      let bin = g:{binname}
    endif

    if !executable(bin) 
      echo "gounit-vim: ". binary ." not found. Installing ". importPath . " to folder " . go_bin_path

      let [l:out, l:err] = s:ExecCmd(l:run_cmd + [l:importPath])
      if l:err
        echom "Error installing " . l:importPath . ": " . l:out
      endif
    endif
  endfor
  echom "gounit-vim: all " . final_msg . " have been installed."
  if &filetype == "go"
    call s:AddUnitCommand()
  endif
endfunction


"""""""""""""""""""""""""""""""""""""""
" plugin functionality
if !exists('g:gounit_bin')
  let g:gounit_bin = 'gounit'
endif

function! s:Tests(...) range
  let bin = g:gounit_bin
  if !executable(bin)
    echom 'gounit-vim: gounit binary not found.'
    return
  endif

  let funcLine = 0
  for lineno in range(a:firstline, a:lastline)
    let funcName = matchstr(getline(lineno), '^func\s*\(([^)]\+)\)\=\s*\zs\w\+\ze(')
    if funcName != ''
      let funcLine = lineno
    endif
  endfor
  if funcLine == 0
    echom 'gounit-vim: No function selected!'
    return
  endif

  " check if arguments were passed
  " then checks if template exsits
  " if everything is ok then template is being changed
  " and next time GoUnit is used it will be used
  if a:0
    call s:TemplateUse(a:1)
  endif

  let file = expand('%')
  let out = system(bin . ' gen -l ' . shellescape(funcLine) . ' -i ' . shellescape(file))
  if out != ''
    echom 'gounit-vim: ' . out
  else
    echom 'gounit-vim: test successfully generated'
  endif
endfunction

" TemplateUse is used to set template for go-unit by its name
function! s:TemplateUse(tmpl_name)
  if !executable('gounit')
    echom 'gounit-vim: gounit binary not found.'
    return
  endif
  let l:res = s:ParseTemplResult()
  let l:count = 0
  for i in l:res
    if i == a:tmpl_name
      let l:count += 1
    endif
  endfor
  if !l:count
    echo 'gounit-vim: error no such template'
    return -1
  endif
  " runs a gounit command with a given template
  call system(s:plugin_name . ' template use ' . a:tmpl_name)
  echom "gounit-vim: template has been changed to " . a:tmpl_name
endfunction

" simply removes template from the list of your templates
function! s:TemplateDel(tmpl_name)
  if !executable('gounit')
    echom 'gounit-vim: gounit binary not found.'
    return
  endif
  if a:tmpl_name == 'default'
    echom 'gounit-vim: cannot delete default template'
    return -1
  endif
  let l:res = s:ParseTemplResult()
  let l:count = 0
  for i in l:res
    if i == a:tmpl_name
      let l:count += 1
    endif
  endfor
  if !l:count
    echo 'gounit-vim: error no such template'
    return -1
  endif
  call system(s:plugin_name . ' template remove ' . a:tmpl_name)
  echom 'gounit-vim: ' . a:tmpl_name . ' template has been removed'
endfunction

"""""""""""""""""""""""""""""""""""""""
" parsing result of a command template list
" to find out what templates we can use
" and return them as an array
function! s:ParseTemplResult(...)
  let l:templates = system(s:plugin_name . ' template list')
  let l:templates = split(l:templates, '\n')[1:]
  let l:result = []
  for i in l:templates
    if !len(i)
      continue
    endif
    for j in split(i, ' ')
      if j == '*' || j == ''
        continue
      endif
      let l:result = add(l:result, j)
    endfor
  endfor
  return l:result
endfunction

" adds new template file into gounit
" if no arguments were passed it uses current buffer
function! s:TemplateAdd(...)
  if !executable('gounit')
    echom 'gounit-vim: gounit binary not found.'
    return
  endif
  if !a:0 
    let l:filepath = expand('%:p')
  else
    let l:filepath = a:1
    if !filereadable(l:filepath)
      echo 'gounit-vim: ' . l:filepath . ' is not found'
      return -1
    endif
  endif
  let l:callResult = system(s:plugin_name . ' template add ' . l:filepath)
  if l:callResult != ""
    echo l:callResult
  else
    echom 'gounit-vim: ' . split(l:filepath, '\/')[-1] . ' template has been added to your gounit list'
  endif
endfunction

" function calls template list command and lists all installed
" templates, current template is marked by * symbol 
function! s:TemplateList()
  if !executable('gounit')
    echom 'gounit-vim: gounit binary not found.'
    return
  endif
  let l:templates = system(s:plugin_name . ' template list')
  let l:templates = split(l:templates, '\n')[1:]
  echom 'gounit-vim: list of installed templates'
  for i in l:templates
    echo i
  endfor
endfunction

" defines new command with autocomplete functionlist
function! s:TemplateCommands()
  let l:result = s:ParseTemplResult()
  command! -nargs=1 -complete=customlist,s:ParseTemplResult GoUnitTemplateDel call s:TemplateDel(<f-args>)
  command! -nargs=1 -complete=customlist,s:ParseTemplResult GoUnitTemplateUse call s:TemplateUse(<f-args>)
  command! -nargs=? -complete=file GoUnitTemplateAdd call s:TemplateAdd(<f-args>)
  command! GoUnitTemplateList call s:TemplateList()
  " TODO: TemplateEdit
endfunction

function! s:AddUnitCommand()
  command! -range -buffer -nargs=? -complete=customlist,s:ParseTemplResult GoUnit <line1>,<line2>call s:Tests(<f-args>)
endfunction

" function checks all binaries and after that calls other init functions
" for gounit plugin
function! s:GoUnitCheck()
  if !executable('go')
    return -1
  endif
  if !executable('gounit')
    return -1
  endif
endfunction

let s:plugin_name = 'gounit'

" Loads go-unit commands only for *.go files 
augroup go-unit
	autocmd BufNewFile *.go 
	\  if s:GoUnitCheck() != -1
	\|	call s:AddUnitCommand()
	\| endif
	autocmd BufRead *.go 
	\  if s:GoUnitCheck() != -1
	\|	call s:AddUnitCommand()
	\| endif
augroup end

" create template cmds
if s:GoUnitCheck() != 1
  call s:TemplateCommands()
endif

" inits function to download gounit binaries
command! GoUnitInstallBinaries call s:GoUnitInstall()

" vim: sw=2 ts=2 et
