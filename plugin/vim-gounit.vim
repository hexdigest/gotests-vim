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
	if !executable('gounit')
		" check if we can download and install gounit with go and git
		let l:err = s:CheckBinaries()
		if l:err != 0
			return
		endif
		if s:DefaultPath() == ""
			echohl Error
			echomsg "vim.go: $GOPATH is not set and 'go env GOPATH' returns empty"
			echohl None
			return
		endif
		let l:go_bin_path = s:DefaultPath()
		let l:pluginPath = 'github.com/hexdigest/gounit/cmd/gounit'

		" when shellslash is set on MS-* systems, shellescape puts single quotes
		" around the output string. cmd on Windows does not handle single quotes
		" correctly. Unsetting shellslash forces shellescape to use double quotes
		" instead.
		let l:resetshellslash = 0
		if has('win32') && &shellslash
			let l:resetshellslash = 1
			set noshellslash
		endif

		echo "Go: ". "go-unit" ." not found. Installing ". pluginPath . " to folder " . go_bin_path
		let l:run_cmd = ['go', 'get', '-u']
		let [l:out, l:err] = s:ExecCmd(l:run_cmd + [l:pluginPath])
		if l:err
			echom "Error installing " . pluginPath . ": " . l:out
		endif
    echo 'gounit installation is complete'
  else
    echo 'gounit is already installed'
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
    let l:res = ParseTemplResult()
    let l:count = 0
    for i in l:res
      if i == a:1
        let l:count += 1
      endif
    endfor
    if !l:count
      echo 'error no such template'
      return -1
    endif
    " runs a gounit command with a given template
    call system(s:plugin_name . ' template use ' . a:1)
  endif

  let file = expand('%')
  let out = system(bin . ' gen -l ' . shellescape(funcLine) . ' -i ' . shellescape(file))
  if out != ''
    echom 'gounit-vim: ' . out
  else
    echom 'gounit-vim: test successfully generated'
  endif
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


" defines new command with autocomplete functionlist
function! s:TemplateCommands()
  let l:result = s:ParseTemplResult()
  command! -range -nargs=? -complete=customlist,s:ParseTemplResult GoUnit <line1>,<line2>call s:Tests(<f-args>)
endfunction


" function checks all binaries and after that calls other init functions
" for gounit plugin
function! s:GoUnitInit()
  let s:plugin_name = 'gounit'
  if !executable('go')
    echohl Error | echomsg "go executable not found." | echohl None
    return -1
  endif
  if !executable('gounit')
    echohl Error | echomsg "gounit is not installed" | echohl None
    return -1
  endif
endfunction


" Loads go-unit commands only for *.go files 
augroup go-unit
	autocmd BufEnter *.go 
	\  if s:GoUnitInit() != -1
	\|	call s:TemplateCommands()
	\| endif
augroup end


" inits function to download gounit binaries
command! GoUnitInstallBinaries call s:GoUnitInstall()

" vim: sw=2 ts=2 et
